module frontend.parser.parse_stmt;

import frontend.lexer.tokens;
import frontend.parser.ast;
import frontend.parser.parser;

class ParseStmt
{
private:
    Parser p;
public:
    this(Parser p)
    {
        this.p = p;
    }

    Node* parse()
    {
        switch (p.peek().kind)
        {
            case TokenKind.Return:
                Node* n = new Node();
                n.kind = NodeKind.ReturnStmt;
                n.pos = p.advance().pos;
                n.ret.val = p.expr.parse();
                n.typeExpr = n.ret.val.typeExpr;
                return n;
            default:
                return null;
        }
    }
}
