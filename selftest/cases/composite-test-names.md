---
composite_test_names: true
---

# Composite Test Names

This file tests the composite_test_names feature which creates hierarchical test
names from all parent headings.

## Feature: Basic Arithmetic

### Given two numbers

#### When adding them

```scrut
$ echo $((2 + 3))
5
```

#### When subtracting them

```scrut
$ echo $((5 - 2))
3
```

### Given negative numbers

#### When multiplying them

```scrut
$ echo $((-2 * -3))
6
```

## Feature: String Operations

### Given a string

Concatenation test

```scrut
$ echo "hello" "world"
hello world
```

### Given multiple strings

```scrut
$ echo "a" "b" "c"
a b c
```

## Custom Separator Test

The following tests verify the composite naming works at various heading depths.

### Level 3

#### Level 4

##### Level 5

```scrut
$ echo "deep nesting works"
deep nesting works
```
