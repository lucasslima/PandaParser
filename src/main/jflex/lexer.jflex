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
    private int commentLevel;
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

%state COMMENT
%state STR

%%

<YYINITIAL>{
[ \t\f\n\r]+          { /* skip */ }

// complete com suas regras léxicas principais

}


//<COMMENT>{

/* acrescente as regras léxicas para tratar comentários de bloco */

//}


//<STR>{

/* acrescente as regras léxicas para tratar literais strings */

//}

.           { error("invalid character: [" + yytext() + "]"); }
