module frontend.parser.parser;

import std.stdio;
import frontend.lexer.tokens;
import frontend.parser.parse_decl;
import frontend.parser.parse_expr;
import frontend.parser.parse_stmt;
import frontend.parser.parse_type;
import frontend.parser.ast;
import common.reporter;

class Parser
{
private:
    Token[] tokens;
    uint offset;

public:
    ReporterError error;
    ParseDecl decl;
    ParseExpr expr;
    ParseStmt stmt;
    ParseType type;

    pragma(inline, true)
    bool isAtEnd()
    {
        return offset == tokens.length;
    }

    pragma(inline, true)
    Token advance()
    {
        if (isAtEnd())
            return peek();
        return tokens[offset++];
    }

    pragma(inline, true)
    Token consume(TokenKind kind, string msg)
    {
        if (peek().kind != kind)
        {
            error.makeError(msg, peek().pos);
            throw new Exception(msg);
        }
        return advance();
    }

    pragma(inline, true)
    Token peek()
    {
        return tokens[offset];
    }

    pragma(inline, true)
    bool check(TokenKind kind)
    {
        return tokens[offset].kind == kind;
    }

    pragma(inline, true)
    bool match(TokenKind[] kinds)
    {
        foreach (TokenKind kind; kinds)
            if (peek().kind == kind)
            {
                advance();
                return true;
            }
        return false;
    }

    Node* parse()
    {
        if (isDecl())
            return decl.parse();
        if (isStmt())
            return stmt.parse();
        return expr.parse();
    }

    bool isDecl()
    {
        switch (peek().kind)
        {
        case TokenKind.Fn:
        case TokenKind.Let:
        case TokenKind.Const:
        case TokenKind.Def:
            return true;
        default:
            return false;
        }
    }

    bool isStmt()
    {
        switch (peek().kind)
        {
        case TokenKind.If:
        case TokenKind.Import:
        case TokenKind.Return:
        case TokenKind.Defer:
            return true;
        default:
            return false;
        }
    }

    this(ref Token[] tokens, ReporterError error)
    {
        this.decl = new ParseDecl(this);
        this.stmt = new ParseStmt(this);
        this.expr = new ParseExpr(this);
        this.type = new ParseType(this);
        this.tokens = tokens;
        this.error = error;
    }

    Node* program()
    {
        Node[] body;
        Node* n = new Node();
        n.kind = NodeKind.Program;
        while (!isAtEnd() && peek().kind != TokenKind.Eof)
        {
            Node* node = parse();
            if (node !is null)
                body ~= *node;
        }
        n.prog.body = body;
        return n;
    }
}
