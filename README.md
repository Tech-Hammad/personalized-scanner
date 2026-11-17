# Hammad Mini C++ Lexical Analyzer

## Personalization

- First name: `Hammad`
- Roll number: `793`
- `A = 7 + 9 + 3 = 19`
- `N = 6` alphabetic characters
- `V = 2` vowels
- `A mod 3 = 1`: identifiers start with `_d` and then contain letters/digits.
- `A mod 4 = 3`: decimal integers and floating-point numbers are accepted.
- `V mod 2 = 0`: `##` is the personalized comment marker.
- `N mod 5 + 1 = 2`: strings require at least two visible characters.

## Language specification

### Keywords (exactly 16)

`if`, `else`, `while`, `for`, `int`, `float`, `return`, `print`, `agar`,
`warna`, `jabtak`, `dikhao`, `Hammad$`, `Ham@`, `Roll793#`, `HammadEnd$`

### Literals and constants

- Boolean literals: `haan$`, `nahin$`
- Predefined constants: `MAX@`, `PI#`
- Decimal integer: `[0-9]+`
- Floating point: `[0-9]+\.[0-9]+`
- Identifier: `_d[A-Za-z0-9]*`
- String escapes: `\n`, `\t`, `\"`, `\\`

### Operators

Exactly five operators are supported: `+`, `>=`, `:=`, `&&`, `<<<`.
The personalized operators are `:=` and `<<<`.

### Punctuation and comments

Punctuation: `;`, `,`, `(`, `)`, `{`, `}`, `[`, `]`.
Comments: `// ...` and `## ...`; comments are counted and ignored.

## Build and run

With Flex and a C++ compiler installed:

```text
flex scanner.l
g++ lex.yy.c -o scanner.exe
scanner.exe valid_test.txt
scanner.exe invalid_test.txt
```

Each run writes `tokens.txt`, `errors.txt`, and `summary.txt`. The invalid
input intentionally causes a non-zero exit status after reporting all errors.

## Rule priority and malformed input

Keyword, Boolean, and constant rules appear before the identifier fallback.
Malformed numeric rules appear before valid numeric rules, so inputs such as
`0xG5`, `0b1021`, `45..7`, and `1.2e+` are reported as one malformed number
instead of being split into smaller valid tokens. The scanner also reports
invalid identifier patterns, invalid escapes, unterminated strings, invalid
character literals, unknown symbols, and incomplete operators.
