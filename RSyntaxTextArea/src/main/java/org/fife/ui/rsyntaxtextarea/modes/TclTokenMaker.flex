/*
 * 10/03/2007
 *
 * TclTokenMaker.java - Scanner for the Tcl programming language.
 * 
 * This library is distributed under a modified BSD license.  See the included
 * LICENSE file for details.
 */
package org.fife.ui.rsyntaxtextarea.modes;

import java.io.*;
import javax.swing.text.Segment;

import org.fife.ui.rsyntaxtextarea.*;


/**
 * Scanner for the Tcl programming language.<p>
 *
 * This implementation was created using
 * <a href="http://www.jflex.de/">JFlex</a> 1.4.1; however, the generated file
 * was modified for performance.  Memory allocation needs to be almost
 * completely removed to be competitive with the handwritten lexers (subclasses
 * of <code>AbstractTokenMaker</code>, so this class has been modified so that
 * Strings are never allocated (via yytext()), and the scanner never has to
 * worry about refilling its buffer (needlessly copying chars around).
 * We can achieve this because RText always scans exactly 1 line of tokens at a
 * time, and hands the scanner this line as an array of characters (a Segment
 * really).  Since tokens contain pointers to char arrays instead of Strings
 * holding their contents, there is no need for allocating new memory for
 * Strings.<p>
 *
 * The actual algorithm generated for scanning has, of course, not been
 * modified.<p>
 *
 * If you wish to regenerate this file yourself, keep in mind the following:
 * <ul>
 *   <li>The generated <code>TclTokenMaker.java</code> file will contain two
 *       definitions of both <code>zzRefill</code> and <code>yyreset</code>.
 *       You should hand-delete the second of each definition (the ones
 *       generated by the lexer), as these generated methods modify the input
 *       buffer, which we'll never have to do.</li>
 *   <li>You should also change the declaration/definition of zzBuffer to NOT
 *       be initialized.  This is a needless memory allocation for us since we
 *       will be pointing the array somewhere else anyway.</li>
 *   <li>You should NOT call <code>yylex()</code> on the generated scanner
 *       directly; rather, you should use <code>getTokenList</code> as you would
 *       with any other <code>TokenMaker</code> instance.</li>
 * </ul>
 *
 * @author Robert Futrell
 * @version 0.5
 *
 */
%%

%public
%class TclTokenMaker
%extends AbstractJFlexCTokenMaker
%unicode
%type org.fife.ui.rsyntaxtextarea.Token


%{


	/**
	 * Constructor.  This must be here because JFlex does not generate a
	 * no-parameter constructor.
	 */
	public TclTokenMaker() {
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int tokenType) {
		addToken(zzStartRead, zzMarkedPos-1, tokenType);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param tokenType The token's type.
	 */
	private void addToken(int start, int end, int tokenType) {
		int so = start + offsetShift;
		addToken(zzBuffer, start,end, tokenType, so);
	}


	/**
	 * Adds the token specified to the current linked list of tokens.
	 *
	 * @param array The character array.
	 * @param start The starting offset in the array.
	 * @param end The ending offset in the array.
	 * @param tokenType The token's type.
	 * @param startOffset The offset in the document at which this token
	 *                    occurs.
	 */
	@Override
	public void addToken(char[] array, int start, int end, int tokenType, int startOffset) {
		super.addToken(array, start,end, tokenType, startOffset);
		zzStartRead = zzMarkedPos;
	}


	/**
	 * {@inheritDoc}
	 */
	@Override
	public String[] getLineCommentStartAndEnd(int languageIndex) {
		return new String[] { "//", null };
	}


	/**
	 * Returns the first token in the linked list of tokens generated
	 * from <code>text</code>.  This method must be implemented by
	 * subclasses so they can correctly implement syntax highlighting.
	 *
	 * @param text The text from which to get tokens.
	 * @param initialTokenType The token type we should start with.
	 * @param startOffset The offset into the document at which
	 *        <code>text</code> starts.
	 * @return The first <code>Token</code> in a linked list representing
	 *         the syntax highlighted text.
	 */
	public Token getTokenList(Segment text, int initialTokenType, int startOffset) {

		resetTokenList();
		this.offsetShift = -text.offset + startOffset;

		// Start off in the proper state.
		int state = Token.NULL;

		s = text;
		try {
			yyreset(zzReader);
			yybegin(state);
			return yylex();
		} catch (IOException ioe) {
			ioe.printStackTrace();
			return new TokenImpl();
		}

	}


	/**
	 * Refills the input buffer.
	 *
	 * @return      <code>true</code> if EOF was reached, otherwise
	 *              <code>false</code>.
	 */
	private boolean zzRefill() {
		return zzCurrentPos>=s.offset+s.count;
	}


	/**
	 * Resets the scanner to read from a new input stream.
	 * Does not close the old reader.
	 *
	 * All internal variables are reset, the old input stream 
	 * <b>cannot</b> be reused (internal buffer is discarded and lost).
	 * Lexical state is set to <tt>YY_INITIAL</tt>.
	 *
	 * @param reader   the new input stream 
	 */
	public final void yyreset(Reader reader) {
		// 's' has been updated.
		zzBuffer = s.array;
		/*
		 * We replaced the line below with the two below it because zzRefill
		 * no longer "refills" the buffer (since the way we do it, it's always
		 * "full" the first time through, since it points to the segment's
		 * array).  So, we assign zzEndRead here.
		 */
		//zzStartRead = zzEndRead = s.offset;
		zzStartRead = s.offset;
		zzEndRead = zzStartRead + s.count - 1;
		zzCurrentPos = zzMarkedPos = zzPushbackPos = s.offset;
		zzLexicalState = YYINITIAL;
		zzReader = reader;
		zzAtBOL  = true;
		zzAtEOF  = false;
	}


%}

Letter							= [A-Za-z]
NonzeroDigit						= [1-9]
Digit							= ("0"|{NonzeroDigit})
HexDigit							= ({Digit}|[A-Fa-f])
OctalDigit						= ([0-7])
EscapedSourceCharacter				= ("u"{HexDigit}{HexDigit}{HexDigit}{HexDigit})
NonSeparator						= ([^\t\f\r\n\ \(\)\{\}\[\]\;\,\.\=\>\<\!\~\?\:\+\-\*\/\&\|\^\%\"\']|"#"|"\\")
IdentifierStart					= ({Letter}|"_"|"$")
IdentifierPart						= ({IdentifierStart}|{Digit}|("\\"{EscapedSourceCharacter}))

LineTerminator				= (\n)
WhiteSpace				= ([ \t\f])

UnclosedStringLiteral		= ([\"]([\\].|[^\\\"])*[^\"]?)
StringLiteral				= ({UnclosedStringLiteral}[\"])

LineCommentBegin			= "#"

IntegerHelper1				= (({NonzeroDigit}{Digit}*)|"0")
IntegerHelper2				= ("0"(([xX]{HexDigit}+)|({OctalDigit}*)))
IntegerLiteral				= ({IntegerHelper1}[lL]?)
HexLiteral				= ({IntegerHelper2}[lL]?)
FloatHelper1				= ([fFdD]?)
FloatHelper2				= ([eE][+-]?{Digit}+{FloatHelper1})
FloatLiteral1				= ({Digit}+"."({FloatHelper1}|{FloatHelper2}|{Digit}+({FloatHelper1}|{FloatHelper2})))
FloatLiteral2				= ("."{Digit}+({FloatHelper1}|{FloatHelper2}))
FloatLiteral3				= ({Digit}+{FloatHelper2})
FloatLiteral				= ({FloatLiteral1}|{FloatLiteral2}|{FloatLiteral3}|({Digit}+[fFdD]))
ErrorNumberFormat			= (({IntegerLiteral}|{HexLiteral}|{FloatLiteral}){NonSeparator}+)

Separator					= ([\(\)\{\}\[\]])
Separator2				= ([\;,.])

Operator					= ("="|"!"|"+"|"-"|"*"|"/"|">"=?|"<"=?|"%"|"&"|"|"|"^"|"~")

Identifier				= ({IdentifierStart}{IdentifierPart}*)
ErrorIdentifier			= ({NonSeparator}+)


%%

/* Keywords */
<YYINITIAL> "append"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "array"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "auto_mkindex"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "concat"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "console"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "eval"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "expr"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "format"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "global"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "set"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "trace"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "unset"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "upvar"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "join"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "lappend"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "lindex"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "linsert"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "list"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "llength"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "lrange"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "lreplace"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "lsearch"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "lsort"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "split"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "scan"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "string"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "regexp"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "regsub"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "if"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "else"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "elseif"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "switch"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "for"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "foreach"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "while"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "break"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "continue"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "proc"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "return"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "source"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "unkown"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "uplevel"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "cd"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "close"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "eof"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "file"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "flush"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "gets"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "glob"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "open"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "read"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "puts"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "pwd"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "seek"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "tell"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "catch"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "error"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "exec"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "pid"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "after"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "time"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "exit"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "history"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "rename"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "info"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "ceil"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "floor"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "round"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "incr"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "hypot"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "abs"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "acos"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "cos"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "cosh"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "asin"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "sin"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "sinh"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "atan"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "atan2"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "tan"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "tanh"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "log"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "log10"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "fmod"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "pow"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "hypot"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "sqrt"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "double"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "int"				{ addToken(Token.RESERVED_WORD); }

<YYINITIAL> "bind"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "button"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "canvas"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "checkbutton"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "destroy"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "entry"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "focus"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "frame"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "grab"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "image"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "label"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "listbox"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "lower"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "menu"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "menubutton"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "message"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "option"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "pack"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "placer"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "radiobutton"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "raise"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "scale"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "scrollbar"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "selection"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "send"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "text"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "tk"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "tkerror"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "tkwait"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "toplevel"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "update"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "winfo"				{ addToken(Token.RESERVED_WORD); }
<YYINITIAL> "wm"				{ addToken(Token.RESERVED_WORD); }


<YYINITIAL> {

	{LineTerminator}				{ addNullToken(); return firstToken; }

	{Identifier}					{ addToken(Token.IDENTIFIER); }

	{WhiteSpace}+					{ addToken(Token.WHITESPACE); }

	/* String/Character literals. */
	{StringLiteral}				{ addToken(Token.LITERAL_STRING_DOUBLE_QUOTE); }
	{UnclosedStringLiteral}			{ addToken(Token.ERROR_STRING_DOUBLE); addNullToken(); return firstToken; }

	/* Comment literals. */
	{LineCommentBegin}.*			{ addToken(Token.COMMENT_EOL); addNullToken(); return firstToken; }

	/* Separators. */
	{Separator}					{ addToken(Token.SEPARATOR); }
	{Separator2}					{ addToken(Token.IDENTIFIER); }

	/* Operators. */
	{Operator}					{ addToken(Token.OPERATOR); }

	/* Numbers */
	{IntegerLiteral}				{ addToken(Token.LITERAL_NUMBER_DECIMAL_INT); }
	{HexLiteral}					{ addToken(Token.LITERAL_NUMBER_HEXADECIMAL); }
	{FloatLiteral}					{ addToken(Token.LITERAL_NUMBER_FLOAT); }
	{ErrorNumberFormat}				{ addToken(Token.ERROR_NUMBER_FORMAT); }

	{ErrorIdentifier}				{ addToken(Token.ERROR_IDENTIFIER); }

	/* Ended with a line not in a string or comment. */
	<<EOF>>						{ addNullToken(); return firstToken; }

	/* Catch any other (unhandled) characters and flag them as bad. */
	.							{ addToken(Token.ERROR_IDENTIFIER); }

}