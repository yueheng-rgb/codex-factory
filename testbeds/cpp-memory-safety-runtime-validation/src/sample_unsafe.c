/* sample_unsafe.c — MOCK C file demonstrating COMMON UNSAFE PATTERNS
   This file is for VALIDATION TESTING ONLY. It contains intentional
   unsafe patterns that SHOULD be caught by invariants.
   IT IS NOT INTENDED TO BE COMPILED — it serves as a code review target. */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* UNSAFE-001: gets() — unsafe, no bounds checking */
void unsafe_gets_example() {
    char buffer[64];
    gets(buffer);  /* NEVER use gets() */
    printf("%s\n", buffer);
}

/* UNSAFE-002: strcpy without bounds check */
void unsafe_strcpy_example(const char* input) {
    char buffer[64];
    strcpy(buffer, input);  /* No bounds check */
}

/* UNSAFE-003: memcpy with untrusted size */
void unsafe_memcpy_example(void* dest, const void* src, size_t size) {
    memcpy(dest, src, size);  /* size not validated */
}

/* UNSAFE-004: use-after-free */
void unsafe_use_after_free_example() {
    char* ptr = malloc(100);
    free(ptr);
    ptr[0] = 'X';  /* USE AFTER FREE */
}

/* UNSAFE-005: double free */
void unsafe_double_free_example() {
    char* ptr = malloc(100);
    free(ptr);
    free(ptr);  /* DOUBLE FREE */
}

/* UNSAFE-006: null pointer dereference */
void unsafe_null_deref_example() {
    char* ptr = NULL;
    printf("%c\n", *ptr);  /* NULL DEREFERENCE */
}

/* UNSAFE-007: integer overflow in allocation */
void* unsafe_overflow_alloc_example(size_t count, size_t elem_size) {
    return malloc(count * elem_size);  /* Overflow if count * elem_size > SIZE_MAX */
}

/* UNSAFE-008: format string vulnerability */
void unsafe_format_string_example(const char* user_input) {
    printf(user_input);  /* Should be printf("%s", user_input) */
}

/* UNSAFE-009: scanf without length limit */
void unsafe_scanf_example() {
    char buffer[32];
    scanf("%s", buffer);  /* No length limit */
}
