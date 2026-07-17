# Business Invariant Engine v1.0.0
# Part of: FACTORY-R2.13
# Generates business invariant specs based on risk profiles and task context.
# Outputs structured invariant list for Verifier and Test Engineer consumption.

$INVARIANT_LIBRARY = @(
    @{
        invariantId = "INV-001"
        name = "price_non_negative"
        category = "financial"
        description = "Product price must never be negative"
        scope = "Product.price"
        checkType = "pre-condition"
        severity = "BLOCKER"
        rule = "When creating or updating a product, price >= 0"
        testExpression = "expect(product.price).toBeGreaterThanOrEqual(0)"
        appliesTo = @("CRITICAL", "L_CLASS")
    },
    @{
        invariantId = "INV-002"
        name = "price_not_zero_unless_explicit_free"
        category = "financial"
        description = "Zero price requires explicit free flag"
        scope = "Product.price, Product.isFree"
        checkType = "pre-condition"
        severity = "CRITICAL"
        rule = "If price == 0, the entity must have an explicit isFree=true flag or documented reason"
        testExpression = "if (product.price === 0) expect(product.isFree).toBe(true)"
        appliesTo = @("CRITICAL", "L_CLASS")
    },
    @{
        invariantId = "INV-003"
        name = "inventory_non_negative"
        category = "data-integrity"
        description = "Inventory count must never go below zero"
        scope = "Product.inventory, Product.stock"
        checkType = "invariant-check"
        severity = "BLOCKER"
        rule = "After any inventory operation, count >= 0"
        testExpression = "expect(product.inventory).toBeGreaterThanOrEqual(0)"
        appliesTo = @("CRITICAL", "L_CLASS")
    },
    @{
        invariantId = "INV-004"
        name = "order_total_matches_items"
        category = "financial"
        description = "Order total must equal sum of line items"
        scope = "Order.total, OrderItem.price * qty"
        checkType = "post-condition"
        severity = "BLOCKER"
        rule = "order.total === SUM(line_item.price * line_item.quantity)"
        testExpression = "expect(order.total).toBe(sumOfItems)"
        appliesTo = @("CRITICAL", "L_CLASS")
    },
    @{
        invariantId = "INV-005"
        name = "status_transition_allowed"
        category = "state-machine"
        description = "Status changes must follow allowed transitions"
        scope = "Any entity with status field"
        checkType = "pre-condition"
        severity = "BLOCKER"
        rule = "status change: fromStatus -> toStatus must be in allowedTransitions[fromStatus]"
        testExpression = "expect(allowedTransitions[fromStatus]).toContain(toStatus)"
        appliesTo = @("HIGH", "CRITICAL", "L_CLASS")
    },
    @{
        invariantId = "INV-006"
        name = "archived_entity_not_mutable"
        category = "data-integrity"
        description = "Archived/discontinued entities cannot be modified"
        scope = "Any entity with archived/discontinued status"
        checkType = "pre-condition"
        severity = "BLOCKER"
        rule = "If entity.status in (archived, discontinued), reject all write operations"
        testExpression = "expect(() => updateArchivedEntity()).toThrow()"
        appliesTo = @("HIGH", "CRITICAL", "L_CLASS")
    },
    @{
        invariantId = "INV-007"
        name = "user_cannot_modify_protected_fields"
        category = "access-control"
        description = "Users cannot modify fields they don''t own or that are system-protected"
        scope = "createdBy, createdAt, id, role, permissions"
        checkType = "pre-condition"
        severity = "BLOCKER"
        rule = "Protected fields (createdBy, createdAt, id) cannot be set by non-admin users"
        testExpression = "expect(nonAdminUpdateResult.error.code).toBe('FORBIDDEN')"
        appliesTo = @("HIGH", "CRITICAL", "L_CLASS")
    },
    @{
        invariantId = "INV-008"
        name = "payment_idempotency_required"
        category = "idempotency"
        description = "All payment/deduction operations must have idempotency protection"
        scope = "Payment, deduction, quota operations"
        checkType = "invariant-check"
        severity = "BLOCKER"
        rule = "Every payment/deduction request must include idempotencyKey; duplicate key with same payload returns cached result"
        testExpression = "expect(duplicatePaymentResult).toEqual(originalPaymentResult)"
        appliesTo = @("CRITICAL", "L_CLASS")
    },
    @{
        invariantId = "INV-009"
        name = "destructive_action_requires_confirmation"
        category = "security"
        description = "Delete/destroy operations require explicit confirmation"
        scope = "DELETE endpoints, destroy operations"
        checkType = "pre-condition"
        severity = "BLOCKER"
        rule = "DELETE operations must require confirmation token or two-step process"
        testExpression = "expect(deleteWithoutConfirm.statusCode).toBe(400)"
        appliesTo = @("CRITICAL", "L_CLASS")
    }
)

function Get-InvariantsForRiskLevel {
    param([string]$RiskLevel)
    $invariants = @()
    foreach ($inv in $INVARIANT_LIBRARY) {
        if ($inv.appliesTo -contains $RiskLevel) {
            $invariants += $inv
        }
    }
    return $invariants
}

function Get-InvariantByName {
    param([string]$Name)
    foreach ($inv in $INVARIANT_LIBRARY) {
        if ($inv.name -eq $Name) { return $inv }
    }
    return $null
}

function New-InvariantSpec {
    param(
        [Parameter(Mandatory=$true)]$RiskProfile,
        [string[]]$AdditionalInvariants = @(),
        [string]$SpecId = ""
    )

    if (-not $SpecId) { $SpecId = "BIS-$(Get-Date -Format 'yyyyMMddHHmmss')" }

    $invariants = Get-InvariantsForRiskLevel -RiskLevel $RiskProfile.riskLevel

    # Add any explicitly requested invariants from the risk profile
    foreach ($name in $RiskProfile.invariantsSuggested) {
        $inv = Get-InvariantByName -Name $name
        if ($inv -and $invariants.name -notcontains $name) {
            $invariants += $inv
        }
    }

    # Add any additional invariants
    foreach ($name in $AdditionalInvariants) {
        $inv = Get-InvariantByName -Name $name
        if ($inv -and $invariants.name -notcontains $name) {
            $invariants += $inv
        }
    }

    $blockerCount = ($invariants | Where-Object { $_.severity -eq "BLOCKER" }).Count
    $criticalCount = ($invariants | Where-Object { $_.severity -eq "CRITICAL" }).Count

    return [PSCustomObject]@{
        specId = $SpecId
        profileId = $RiskProfile.profileId
        riskLevel = $RiskProfile.riskLevel
        invariants = @($invariants | Select-Object invariantId, name, category, description, scope, checkType, severity, rule, testExpression)
        invariantCount = $invariants.Count
        blockerCount = $blockerCount
        criticalCount = $criticalCount
        requiredTests = $RiskProfile.requiredTests
        createdAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    }
}
