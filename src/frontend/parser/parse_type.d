module frontend.parser.parse_type;

import frontend.lexer.tokens;
import frontend.parser.ast;
import frontend.parser.parser;
import frontend.types.type_expr;

class ParseType
{
private:
    Parser p;
public:
    this(Parser p)
    {
        this.p = p;
    }

    TypeExpr* parse()
    {
        TypeExpr* primary = parsePrimary();
        if (p.match([TokenKind.Star]))
            return parsePointer(primary);
        return primary;
    }

    TypeExpr* parsePrimary()
    {
        Token tk = p.advance();
        switch (tk.kind)
        {
            case TokenKind.Identifier:
                return TypeExpr.makeNamed(tk.value.str, tk.pos);
            default:
                p.error.makeError("Unknown type.", tk.pos);
                throw new Exception("Unknown type.");
        }
    }

    TypeExpr* parsePointer(TypeExpr* base)
    {
        TypeExpr* type = TypeExpr.makePointer(base);
        if (p.match([TokenKind.Star]))
            return parsePointer(type);
        return type;
    }
}
