module frontend.parser.parse_expr;

import frontend.lexer.tokens;
import frontend.parser.ast;
import frontend.parser.parser;
import frontend.types.type_expr;

enum Precedence : ubyte
{
    Low,
    Sum,
    Mul,
    Call,
    High = 67,
}

class ParseExpr
{
private:
    Parser p;
public:
    this(Parser p)
    {
        this.p = p;
    }

    Node* parse(ubyte level = Precedence.Low)
    {
        Node* left = expression();
        while (level < precedence(p.peek().kind))
            left = infix(left);
        return left;
    }

    Node* expression()
    {
        switch (p.peek().kind)
        {
            case TokenKind.Number:
                Node* n = new Node();
                n.kind = NodeKind.NumberLit;
                n.pos = p.peek().pos;
                n.typeExpr = TypeExpr.makeNamed("long", p.peek().pos);
                n.number.val = p.advance().value.number;
                return n;
            case TokenKind.Double:
                Node* n = new Node();
                n.kind = NodeKind.DoubleLit;
                n.pos = p.peek().pos;
                n.typeExpr = TypeExpr.makeNamed("double", p.peek().pos);
                n.doubleLit.val = p.advance().value.f64;
                return n;
            case TokenKind.Identifier:
                return parseIdentifier();
            case TokenKind.Ampersand:
            case TokenKind.Star:
                return parseUnaryExpr(false, p.advance().kind, p.expr.parse());
            default:
                p.error.makeError("Parser: Unknown token.", p.peek().pos);
                throw new Exception("Parser: Unknown token.");
        }
    }

    Node* parseUnaryExpr(bool post, TokenKind op, Node* val)
    {
        Node* n = new Node();
        n.kind = NodeKind.UnaryExpr;
        n.unary.op = op;
        n.unary.val = val;
        n.unary.post = post;
        n.pos = val.pos;
        return n;
    }

    Node* parseIdentifier()
    {
        Node* n = new Node();
        n.kind = NodeKind.Identifier;
        n.pos = p.peek().pos;
        n.id.val = p.advance().value.str;
        
        // fnName<Types, ...>(args, ...)

        if (p.match([TokenKind.Lt]))
        {
            // generic
            TypeExpr*[] generics;
            while (!p.isAtEnd() && !p.check(TokenKind.Gt))
            {
                generics ~= p.type.parse();
                p.match([TokenKind.Comma]);
            }
            p.consume(TokenKind.Gt, "Expected '>' after generic.");
            // call
            p.consume(TokenKind.LParen, "Expected '('.");
            Node*[] args;
            while (!p.isAtEnd() && !p.check(TokenKind.RParen))
            {
                args ~= p.expr.parse();
                p.match([TokenKind.Comma]);
            }
            p.consume(TokenKind.RParen, "Expected ')' after call.");

            Node* call = new Node();
            call.call.name = n.id.val;
            call.call.generics = generics;
            call.call.args = args;
            call.pos = n.pos;
            return call;
        }
        
        return n;
    }

    Node* parseBinaryExpr(Node* left)
    {
        TokenKind op = p.peek().kind;
        ubyte level = precedence(op);
        p.advance();
        Node* n = new Node();
        n.kind = NodeKind.BinaryExpr;
        n.binary.left = left;
        n.binary.right = parse(level);
        n.binary.op = op;
        return n;
    }

    Node* infix(Node* left)
    {
        switch (p.peek().kind)
        {
            case TokenKind.Plus:
            case TokenKind.Minus:
            case TokenKind.Star:
            case TokenKind.Slash:
            case TokenKind.Modulo:
                return parseBinaryExpr(left);
            default:
                return left;
        }
    }

    ubyte precedence(TokenKind kind)
    {
        switch (kind)
        {
            case TokenKind.Plus:
            case TokenKind.Minus:
                return Precedence.Sum;
            default:
                return Precedence.Low;
        }
    }
}
