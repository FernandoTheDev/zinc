module frontend.lexer.lexer;

import frontend.lexer.tokens;
import std.conv;
import std.stdio;
import std.format;
import common.reporter;

class Lexer
{
private:
    uint offset, loffset;
    uint line = 1;
    string source, dir, filename;
    ReporterError error;
    Token[] tokens;
    TokenKind[string] keywords = [
        "let": TokenKind.Let,
        "const": TokenKind.Const,
        "if": TokenKind.If,
        "else": TokenKind.Else,
        "import": TokenKind.Import,
        "return": TokenKind.Return,
        "defer": TokenKind.Defer,
        "fn": TokenKind.Fn,
    ];

    pragma(inline, true)
    Position makePos(uint startOffset, uint startLine)
    {
        return Position(filename, dir, LinePos(startOffset, startLine), LinePos(loffset, line));
    }

    pragma(inline, true)
    bool isAtEnd()
    {
        return offset == source.length;
    }

    pragma(inline, true)
    char future(uint off = 1)
    {
        if (!isAtEnd())
            return source[offset + off];
        return peek();
    }

    pragma(inline, true)
    char next()
    {
        if (!isAtEnd())
        {
            loffset++;
            return source[offset++];
        }
        return peek();
    }

    pragma(inline, true)
    char peek()
    {
        return source[offset];
    }

    pragma(inline, true)
    bool isAlpha(char ch)
    {
        return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_';
    }

    pragma(inline, true)
    bool isNumeric(char ch)
    {
        return ch >= '0' && ch <= '9';
    }

    pragma(inline, true)
    bool isAlphaNumeric(char ch)
    {
        return isAlpha(ch) || isNumeric(ch);
    }

    pragma(inline, true)
    void pushToken(TokenKind kind, string val, uint start, uint lstart)
    {
        TokenValue value;
        value.str = val;
        tokens ~= Token(kind, value, makePos(start, lstart));
    }

    pragma(inline, true)
    void pushToken(TokenKind kind, long val, uint start, uint lstart)
    {
        TokenValue value;
        value.number = val;
        tokens ~= Token(kind, value, makePos(start, lstart));
    }

    pragma(inline, true)
    char previous()
    {
        if (offset > 0)
        {
            loffset--;
            return source[offset--];
        }
        return peek();
    }

public:
    Token[] tokenize()
    {
        uint start, lstart;
        while (!isAtEnd())
        {
            char ch = next();
            
            if (ch == '\n')
            {
                loffset = 0;
                line++;
                continue;
            }

            if (ch == '\r' || ch == '\t' || ch == ' ')
                continue;

            if (isAlpha(ch))
            {
                string buffer;
                start = loffset;
                lstart = line;
                while (!isAtEnd() && isAlphaNumeric(ch))
                {
                    buffer ~= ch;
                    ch = next();
                }
                previous();
                pushToken(buffer in keywords ? keywords[buffer] : TokenKind.Identifier, buffer, start, lstart);
                continue;
            }

            if (isNumeric(ch))
            {
                string buffer;
                start = loffset;
                lstart = line;
                while (!isAtEnd() && (isNumeric(ch) || ch == '_'))
                {
                    if (ch == '_') { next(); continue; }
                    buffer ~= ch;
                    ch = next();
                }
                previous();
                pushToken(TokenKind.Number, to!long(buffer), start, lstart);
                continue;
            }

            if (ch == '(') { pushToken(TokenKind.LParen, "(", loffset, line); continue; }
            if (ch == ')') { pushToken(TokenKind.RParen, ")", loffset, line); continue; }
            if (ch == '[') { pushToken(TokenKind.LBRacket, "[", loffset, line); continue; }
            if (ch == ']') { pushToken(TokenKind.RBRacket, "]", loffset, line); continue; }
            if (ch == '{') { pushToken(TokenKind.LBRace, "{", loffset, line); continue; }
            if (ch == '}') { pushToken(TokenKind.RBrace, "}", loffset, line); continue; }
            if (ch == '+') { pushToken(TokenKind.Plus, "+", loffset, line); continue; }
            if (ch == '*') { pushToken(TokenKind.Star, "*", loffset, line); continue; }
            if (ch == '/') { pushToken(TokenKind.Slash, "/", loffset, line); continue; }
            if (ch == '-') { pushToken(TokenKind.Minus, "-", loffset, line); continue; }
            if (ch == ':') { pushToken(TokenKind.Colon, ":", loffset, line); continue; }
            if (ch == '=') { pushToken(TokenKind.Equals, "=", loffset, line); continue; }
            if (ch == ';') { pushToken(TokenKind.SemiColon, ";", loffset, line); continue; }

            error.makeError(format("Unknown character '%c'.", ch), makePos(loffset, line));
            continue;
        }
        tokens ~= Token(TokenKind.Eof);
        return tokens;
    }

    this(string source, string filename, string dir, ReporterError error)
    {
        this.source = source;
        this.filename = filename;
        this.dir = dir;
        this.error = error;
    }
}
