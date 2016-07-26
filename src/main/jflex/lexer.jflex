/* -*-Mode: java-*- */

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
StringCharacter = [^\n\r\"\\]|"\\\""
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

\"                    { yybegin(STR); builder.setLength(0); }
//\"(\\.|[^\\\"])*\"    { return tok(LITSTRING, yytext().substring(1,yylength()-1) ); }
\'                    { yybegin(CHARLITERAL);}
\.                    { return tok(DOT); }
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
  \"                             { yybegin(YYINITIAL); return tok(LITSTRING, builder.toString()); }
  {StringCharacter}+            { builder.append( yytext() ); }
  /* escape sequences */

  "\\b"                          { builder.append( '\b' ); }
  "\\t"                          { builder.append( '\t' ); }
  "\\n"                          { builder.append( '\n' ); }
  "\\f"                          { builder.append( '\f' ); }
  "\\r"                          { builder.append( '\r' ); }
  "\\\""                         { builder.append( '\"' ); }
  "\\'"                          { builder.append( '\'' ); }
  "\\\\"                         { builder.append( '\\' ); }
  "\\^@"\"                       { builder.append( 0 ); }
  "\\^I"                        { builder.append( 11);}
  "\\^["                        { builder.append( 33);}
  "\\^\\"                       { builder.append( 34);}
  "\\^]"                        { builder.append( 35);}
  "\\^^"                        { builder.append( 36);}
  "\\^_"                        { builder.append( 37);}
  "\\^?"                        { builder.append( 177);}
  \\[0-3]?{OctDigit}?{OctDigit}  { char val = (char) Integer.parseInt(yytext().substring(1),8);
                        				   builder.append( val ); }
  /* error cases */
  \\.                           { error ("invalid control character in char literal"); }
  //\\.                         { throw new RuntimeException("Illegal escape sequence \""+yytext()+"\""); }
  //{LineTerminator}            { throw new RuntimeException("Unterminated string at end of line"); }

}

<CHARLITERAL> {
  {SingleCharacter}\'            { yybegin(YYINITIAL); return tok(LITCHAR, yytext().charAt(0), new Location(yyline+1, yycolumn),
                                                                                                new Location(yyline+1, yycolumn+1+yylength())); }

  /* escape sequences */
  "\\b"\'                        { yybegin(YYINITIAL); return tok(LITCHAR, '\b', new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\t"\'                        { yybegin(YYINITIAL); return tok(LITCHAR, '\t', new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\n"\'                        { yybegin(YYINITIAL); return tok(LITCHAR, '\n', new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\f"\'                        { yybegin(YYINITIAL); return tok(LITCHAR, '\f', new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\r"\'                        { yybegin(YYINITIAL); return tok(LITCHAR, '\r', new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\\""\'                       { yybegin(YYINITIAL); return tok(LITCHAR, '\"', new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\'"\'                        { yybegin(YYINITIAL); return tok(LITCHAR, '\'', new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\\\"\'                       { yybegin(YYINITIAL); return tok(LITCHAR, '\\', new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength())); }
  "\\^@"\'                       { yybegin(YYINITIAL); return tok(LITCHAR, (char) 0, new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength())); }
  "\\^I'"                        { yybegin(YYINITIAL); return tok(LITCHAR, (char) 9, new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\^['"                        { yybegin(YYINITIAL); return tok(LITCHAR, (char) 27, new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\^\\'"                       { yybegin(YYINITIAL); return tok(LITCHAR, (char) 28, new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\^]'"                        { yybegin(YYINITIAL); return tok(LITCHAR, (char) 29, new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\^^'"                        { yybegin(YYINITIAL); return tok(LITCHAR, (char) 30, new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\^_'"                        { yybegin(YYINITIAL); return tok(LITCHAR, (char) 31, new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  "\\^?'"                        { yybegin(YYINITIAL); return tok(LITCHAR, (char) 127, new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength()));}
  \\[0-3]?{OctDigit}?{OctDigit}\' { yybegin(YYINITIAL);
			                              int val = Integer.parseInt(yytext().substring(1,yylength()-1));
			                            return tok(LITCHAR, (char)val, new Location(yyline+1, yycolumn), new Location(yyline+1, yycolumn+1+yylength())); }

  /* error cases */
  \\[\^].\'                          {  errormsg.Error.error( new Loc(new Location(unit, yyline+1, yycolumn), new Location(unit, yyline+1, yycolumn+1+yylength())), "lexical error: " + "invalid control character in char literal");}
  \\.\'                          {  errormsg.Error.error( new Loc(new Location(unit, yyline+1, yycolumn), new Location(unit, yyline+1, yycolumn+1+yylength())), "lexical error: " + "invalid escape sequence in char literal");}
  .+\'                           {  errormsg.Error.error( new Loc(new Location(unit, yyline+1, yycolumn), new Location(unit, yyline+1, yycolumn+1+yylength())), "lexical error: " + "invalid char literal");}
  \R                             { errormsg.Error.error( new Loc(new Location(unit, yyline+1, yycolumn), new Location(unit, yyline+1, yycolumn+yylength())), "lexical error: " + "unclosed char literal"); }
}