%{
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line_number = 1;
int keyword_count = 0, identifier_count = 0, numeric_count = 0;
int literal_count = 0, boolean_constant_count = 0, operator_count = 0;
int punctuation_count = 0, comment_count = 0, error_count = 0;

FILE *tokens_file;
FILE *errors_file;
FILE *summary_file;

static void emit_token(const char *type, const char *lexeme, const char *attribute)
{
    if (attribute != NULL)
        printf("Line %d: %s -> %s [%s]\n", line_number, type, lexeme, attribute);
    else
        printf("Line %d: %s -> %s\n", line_number, type, lexeme);

    if (attribute != NULL)
        fprintf(tokens_file, "Line %d: %s -> %s [%s]\n",
                line_number, type, lexeme, attribute);
    else
        fprintf(tokens_file, "Line %d: %s -> %s\n",
                line_number, type, lexeme);
}

static void emit_error(const char *message, const char *lexeme)
{
    printf("Line %d: ERROR -> %s \"%s\"\n", line_number, message, lexeme);
    fprintf(errors_file, "Line %d: ERROR -> %s \"%s\"\n",
            line_number, message, lexeme);
    error_count++;
}

static void emit_length_token(const char *type, const char *lexeme, int length)
{
    char attribute[64];
    snprintf(attribute, sizeof(attribute), "Length=%d", length);
    emit_token(type, lexeme, attribute);
}

static int visible_string_length(const char *lexeme)
{
    int length = 0;
    size_t i;
    for (i = 1; i + 1 < strlen(lexeme); i++) {
        if (lexeme[i] == '\\')
            i++;
        length++;
    }
    return length;
}

static void write_summary(void)
{
    fprintf(summary_file, "========== TOKEN SUMMARY ==========\n\n");
    fprintf(summary_file, "Keywords: %d\n", keyword_count);
    fprintf(summary_file, "Identifiers: %d\n", identifier_count);
    fprintf(summary_file, "Numeric literals: %d\n", numeric_count);
    fprintf(summary_file, "String/character literals: %d\n", literal_count);
    fprintf(summary_file, "Boolean literals/constants: %d\n",
            boolean_constant_count);
    fprintf(summary_file, "Operators: %d\n", operator_count);
    fprintf(summary_file, "Punctuations: %d\n", punctuation_count);
    fprintf(summary_file, "Comments ignored: %d\n", comment_count);
    fprintf(summary_file, "Lexical errors: %d\n", error_count);
}

%}

%option noyywrap
%option nodefault

DIGIT       [0-9]
LETTER      [A-Za-z]
ID          _d[A-Za-z0-9]*
FLOAT       {DIGIT}+\.{DIGIT}+
WORD        [A-Za-z_][A-Za-z0-9_]*

%%

[ \t\r]+                    ;
\n                          { line_number++; }

"//"[^\n]*                  { comment_count++; }
"##"[^\n]*                  { comment_count++; }

\"                          {
                                char buffer[4096];
                                int length = 0;
                                int bad_escape = 0;
                                int closed = 0;
                                buffer[length++] = '"';
                                for (;;) {
                                    int c = input();
                                    if (c == EOF || c == '\n') {
                                        if (c == '\n')
                                            line_number++;
                                        buffer[length] = '\0';
                                        if (bad_escape)
                                            emit_error("Invalid escape sequence", buffer);
                                        else
                                            emit_error("Unterminated string", buffer);
                                        break;
                                    }
                                    if (length < (int)sizeof(buffer) - 2)
                                        buffer[length++] = (char)c;
                                    if (c == '\\') {
                                        int escaped = input();
                                        if (escaped == EOF || escaped == '\n') {
                                            if (escaped == '\n')
                                                line_number++;
                                            buffer[length] = '\0';
                                            emit_error("Unterminated string", buffer);
                                            break;
                                        }
                                        if (length < (int)sizeof(buffer) - 2)
                                            buffer[length++] = (char)escaped;
                                        if (escaped != 'n' && escaped != 't' &&
                                            escaped != '"' && escaped != '\\')
                                            bad_escape = 1;
                                    } else if (c == '"') {
                                        closed = 1;
                                        break;
                                    }
                                }
                                if (closed) {
                                    int visible;
                                    buffer[length] = '\0';
                                    visible = visible_string_length(buffer);
                                    if (bad_escape)
                                        emit_error("Invalid escape sequence", buffer);
                                    else if (visible < 2)
                                        emit_error("String must contain at least 2 visible characters",
                                                   buffer);
                                    else {
                                        emit_length_token("STRING", buffer, visible);
                                        literal_count++;
                                    }
                                }
                            }

\'([^\\'\n]|\\[nt'\\])\'   {
                                emit_length_token("CHARACTER", yytext, 1);
                                literal_count++;
                            }

\'([^'\n]|\\.)*\'          { emit_error("Invalid character literal", yytext); }
\'[^'\n]*                  { emit_error("Invalid character literal", yytext); }

0[xX][0-9A-Fa-f]*[G-Zg-z][A-Za-z0-9]* {
                                emit_error("Malformed Number", yytext);
                            }
0[bB][01]*[2-9][0-9]*       { emit_error("Malformed Number", yytext); }
{DIGIT}+\.{DIGIT}*\.{DIGIT}* { emit_error("Malformed Number", yytext); }
{DIGIT}+\.[0-9]*[eE][+-]?  { emit_error("Malformed Number", yytext); }
0[xX][A-Za-z0-9]+           { emit_error("Malformed Number", yytext); }
0[bB][0-9]+                 { emit_error("Malformed Number", yytext); }

{FLOAT}                     {
                                char attribute[80];
                                snprintf(attribute, sizeof(attribute), "Value=%s", yytext);
                                emit_token("FLOAT", yytext, attribute);
                                numeric_count++;
                            }
{DIGIT}+                    {
                                char attribute[80];
                                snprintf(attribute, sizeof(attribute), "Value=%s", yytext);
                                emit_token("INTEGER", yytext, attribute);
                                numeric_count++;
                            }

"if"|"else"|"while"|"for"|"int"|"float"|"return"|"print"|"agar"|"warna"|"jabtak"|"dikhao"|"Hammad$"|"Ham@"|"Roll793#"|"HammadEnd$" {
                                emit_token("KEYWORD", yytext, NULL);
                                keyword_count++;
                            }

"haan$"|"nahin$"             {
                                emit_token("BOOLEAN", yytext, NULL);
                                boolean_constant_count++;
                            }
"MAX@"|"PI#"                 {
                                emit_token("CONSTANT", yytext, NULL);
                                boolean_constant_count++;
                            }

{ID}                         {
                                emit_length_token("IDENTIFIER", yytext, (int)yyleng);
                                identifier_count++;
                            }
{WORD}                       { emit_error("Invalid identifier pattern", yytext); }

">="|"&&"|":="|"<<<"|"+"    {
                                emit_token("OPERATOR", yytext, NULL);
                                operator_count++;
                            }
">"|"&"|":"|"<"             { emit_error("Incomplete or invalid custom operator", yytext); }

";"|","|"("|")"|"{"|"}"|"["|"]" {
                                emit_token("PUNCTUATION", yytext, NULL);
                                punctuation_count++;
                            }

.                            { emit_error("Unknown symbol", yytext); }

%%

int main(int argc, char **argv)
{
    if (argc > 2) {
        fprintf(stderr, "Usage: %s [input-file]\n", argv[0]);
        return 1;
    }

    tokens_file = fopen("tokens.txt", "w");
    errors_file = fopen("errors.txt", "w");
    summary_file = fopen("summary.txt", "w");
    if (tokens_file == NULL || errors_file == NULL || summary_file == NULL) {
        fprintf(stderr, "Unable to create output files.\n");
        return 1;
    }

    if (argc == 2) {
        yyin = fopen(argv[1], "r");
        if (yyin == NULL) {
            perror(argv[1]);
            return 1;
        }
    }

    yylex();
    write_summary();

    if (argc == 2)
        fclose(yyin);
    fclose(tokens_file);
    fclose(errors_file);
    fclose(summary_file);
    return error_count == 0 ? 0 : 2;
}
