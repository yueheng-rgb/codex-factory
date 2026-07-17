param([Parameter(Mandatory=$true)][string]$DecisionPath,[Parameter(Mandatory=$true)][string]$OutputPath)
$d=Get-Content $DecisionPath -Raw|ConvertFrom-Json
$d|Add-Member -NotePropertyName generatedAt -NotePropertyValue (Get-Date -Format "o") -Force
$d|Add-Member -NotePropertyName status -NotePropertyValue "PENDING_VALIDATION" -Force
$d|ConvertTo-Json -Depth 4|Out-File $OutputPath -Encoding utf8
"SPAWN_DECISION_CREATED: $($d.decisionId) -> $OutputPath"
