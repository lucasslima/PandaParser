/* -*-Mode: java-*-
*
* Analisador léxico da linguagem Panda para o primeiro trabalho prático
* da disciplina de Contrução de compiladores.
*
* Alunos: Lucas Sousa Lima
*         Carlos Henrique Prieto Bruckner
*
* */

package parse;

import java.io.Reader;

import errormsg.Loc;

import java_cup.runtime.ComplexSymbolFactory;
import java_cup.runtime.ComplexSymbolFactory.Location;

%%

%public
%final
%class Lexer
%implements parse.Terminals
%line
%column
%cupsym Parse.Tokens
%cup

%eofval{
    return tok(EOF);
%eofval}

%{
    private String unit;
    private ComplexSymbolFactory symbolFactory;
    private int commentLevel=0;
    private StringBuilder builder = new StringBuilder();
    private Location strLeft;

    public Lexer(String unit, Reader input) {
        this(input);
        this.unit = unit;
        this.symbolFactory = new ComplexSymbolFactory();
    }
    
    public String getUnit() {
        return unit;
    }

    private Location locLeft() {
      return new Location(yyline+1, yycolumn+1);
    }

    private Location locRight() {
      return new Location(yyline+1, yycolumn+1+yylength());
    }

    private java_cup.runtime.Symbol tok(int terminalcode) {
      return tok(terminalcode, null);
    }

    private java_cup.runtime.Symbol tok(int terminalcode, Object val) {
      return tok(terminalcode, val, locLeft(), locRight());
    }

    private java_cup.runtime.Symbol tok(int terminalcode, Object val, Location left, Location right) {
      return symbolFactory.newSymbol(
        terminalNames[terminalcode],
        terminalcode,
        left, right,
        val);
    }

    private void error(String message) {
        errormsg.Error.error(
          new Loc(new Location(unit, yyline+1, yycolumn+1),
                  new Location(unit, yyline+1, yycolumn+1+yylength())),
          "lexical error: " + message);
    }
%}
FloatLiteral  = ({FLit1}|{FLit2}|{FLit3}) {Exponent}? [fF]
DoubleLiteral = ({FLit1}|{FLit2}|{FLit3}) {Exponent}?

/* string and character literals */
StringCharacter = [^\n\r\"\\]
SingleCharacter = [^\r\n\'\\]

FLit1    = [0-9]+ \. [0-9]*
FLit2    = \. [0-9]+
FLit3    = [0-9]+
Exponent = [eE] [+-]? [0-9]+

OctIntegerLiteral = 0+ [1-3]? {OctDigit} {1,15}
OctLongLiteral    = 0+ 1? {OctDigit} {1,21} [lL]
OctDigit          = [0-7]

/* main character classes */
LineTerminator = \r|\n|\r\n
InputCharacter = [^\r\n]

%state COMMENT
%state CHARLITERAL
%state STR

%%
<YYINITIAL>{
[ \t\f\n\r]+          { /* skip */ }

// complete com suas regras léxicas principais

if                    { return tok(IF); }
then                  { return tok(THEN); }
else                  { return tok(ELSE); }
let                   { return tok(LET); }
in                    { return tok(IN); }
var                   { return tok(VAR); }
function              { return tok(FUNCTION); }
type                  { return tok(TYPE); }
while                 { return tok(WHILE); }
do					  { return tok(DO); }
break				  { return tok(BREAK); }
nil                   { return tok(NIL); }


:                     { return tok(COLON); }
=                     { return tok(EQ); }
"("                   { return tok(LPAREN); }
")"                   { return tok(RPAREN); }
"["                   { return tok(LBRACK); }
"]"                   { return tok(RBRACK); }
"{"                   { return tok(LBRACE); }
"}"                   { return tok(RBRACE); }
,                     { return tok(COMMA); }
;                     { return tok(SEMICOLON); }
:=                    { return tok(ASSIGN); }

"+"                   { return tok(PLUS); }
"-"                   { return tok(MINUS); }
"*"                   { return tok(TIMES); }
"/"                   { return tok(DIV); }
"%"                   { return tok(MOD); }
"^"                   { return tok(POW); }
"<>"                  { return tok(NE); }
"<"                   { return tok(LT); }
"<="                  { return tok(LE); }
">"                   { return tok(GT); }
">="                  { return tok(GE); }
"&&"				  { return tok(AND); }
"||"				  { return tok(OR); }

@                     { return tok(AT); }

0 | [+|-]?[1-9][0-9]*       { return tok(LITINT, new Long(yytext())); }

[+|-]?{DoubleLiteral}   { return tok(LITREAL, new Double(yytext())); }
true | false            { return tok(LITBOOL, new Boolean(yytext())); }

\"                    { yybegin(STR); builder.setLength(0); strLeft = locLeft(); }
//\"(\\.|[^\\\"])*\"    { return tok(LITSTRING, yytext().substring(1,yylength()-1) ); }
//\'                    { yybegin(CHARLITERAL);}

\'{SingleCharacter}\'   { return tok(LITCHAR, yytext().charAt(1)); }

  /* escape sequences */
\'"\\b"\'                         { return tok(LITCHAR, '\b');}
\'"\\t"\'                         { return tok(LITCHAR, '\t');}
\'"\\n"\'                         { return tok(LITCHAR, '\n');}
\'"\\f"\'                         { return tok(LITCHAR, '\f');}
\'"\\r"\'                         { return tok(LITCHAR, '\r');}
\'"\\\""\'                        { return tok(LITCHAR, '\"');}
\'"\\'"\'                         { return tok(LITCHAR, '\'');}
\'"\\\\"\'                        { return tok(LITCHAR, '\\');}
\'"\\^@"\'                        { return tok(LITCHAR, (char) 0);}
\'"\\^I'"                         { return tok(LITCHAR, (char) 9);}
\'"\\^['"                         { return tok(LITCHAR, (char) 27);}
\'"\\^\\'"                        { return tok(LITCHAR, (char) 28);}
\'"\\^]'"                         { return tok(LITCHAR, (char) 29);}
\'"\\^^'"                         { return tok(LITCHAR, (char) 30);}
\'"\\^_'"                         { return tok(LITCHAR, (char) 31);}
\'"\\^?'"                         { return tok(LITCHAR, (char) 127);}
\'\\[0-3]?{OctDigit}?{OctDigit}\' { char val = (char) Integer.parseInt(yytext().substring(2,yylength()-1)); return tok(LITCHAR, new Character(val) );}
\'\\[\^].\'                      {  error("invalid control character in char literal");}
\'\\.\'                          {  error("invalid escape sequence in char literal");}
\'.+\'                           {  error("invalid char literal");}
\'                               {  error("unclosed char literal"); }
\.                               { return tok(DOT); }

"#" .*                { /* skip */ }
"{#"                  { commentLevel++; yybegin(COMMENT);}
[a-zA-Z][a-zA-Z0-9_]*   { return tok(ID, symbol.Symbol.symbol(yytext())); }

}


<COMMENT> {
   /* acrescente as regras léxicas para tratar comentários de bloco */
   "{#"     {   commentLevel++; }
   "#}"     {
                if (--commentLevel <= 0) {
                    yybegin(YYINITIAL);
                }
            }
    [^{#}\R]+    {    }
    "#"       {    }
    \R        {    }
    <<EOF>>   { error("unclosed comment") ;}
}

<STR>{

  /* acrescente as regras léxicas para tratar literais strings */
  \"                             { yybegin(YYINITIAL); return tok(LITSTRING, builder.toString(),strLeft,locRight()); }
  {StringCharacter}+            { builder.append( yytext()); }
  /* escape sequences */

  "\\b"                          { builder.append( '\b' ); }
  "\\t"                          { builder.append( '\t' ); }
  "\\n"                          { builder.append( '\n' ); }
  "\\f"                          { builder.append( '\f' ); }
  "\\r"                          { builder.append( '\r' ); }
  "\\\""                         { builder.append( '\"' ); }
  "\\'"                          { builder.append( '\'' ); }
  "\\\\"                         { builder.append( '\\' ); }
  "\\^@"                         { builder.append( (char) 0 ); }
  "\\^I"                         { builder.append( (char) 9);}
  "\\^["                         { builder.append( (char) 27);}
  "\\^\\"                        { builder.append( (char) 28);}
  "\\^]"                         { builder.append( (char) 29);}
  "\\^^"                         { builder.append( (char) 30);}
  "\\^_"                         { builder.append( (char) 31);}
  "\\^?"                         { builder.append( (char) 127);}
  \\[0-3]?{OctDigit}?{OctDigit}  { char val = (char) Integer.parseInt(yytext().substring(1));
                        				   builder.append( val ); }
  /* error cases */
  \\[\^].                        { error ("invalid control character in string literal"); }
  \\.                            {  error("invalid escape sequence in string literal");}
  {LineTerminator}               { error("invalid newline in string literal"); }

}
.           { error("invalid character: [" + yytext() + "]"); }
