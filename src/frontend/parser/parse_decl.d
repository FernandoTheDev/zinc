module frontend.parser.parse_decl;

import std.stdio;
import frontend.lexer.tokens;
import frontend.parser.ast;
import frontend.parser.parser;
import frontend.types.type_expr;

class ParseDecl
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
            case TokenKind.Fn:
                return parseFn();
            case TokenKind.Let:
                return parseLet();
            default:
                return null;
        }
    }

    Node* parseLet()
    {
        p.advance();
        Token name = p.consume(TokenKind.Identifier, "Expected an identifier to var name.");
        
        TypeExpr* type;
        if (p.match([TokenKind.Colon]))
            type = p.type.parse();
        
        p.consume(TokenKind.Equals, "Expected '='.");
        Node* val = p.expr.parse();

        Node* n = new Node();
        n.kind = NodeKind.VarDecl;
        n.var.name = name.value.str;
        n.var.value = val;
        n.pos = name.pos;
        return n;
    }

    Node* parseFn()
    {   
        p.advance();
        
        Token name = p.consume(TokenKind.Identifier, "Expected an identifier to function name.");
        TypeExpr*[] generics;

        if (p.match([TokenKind.Lt]))
        {
            while (!p.isAtEnd() && !p.check(TokenKind.Gt))
            {
                generics ~= p.type.parse();
                p.match([TokenKind.Comma]);
            }
            p.consume(TokenKind.Gt, "Expected '>' after generics.");
        }
        
        p.consume(TokenKind.LParen, "Expected '(' after function name.");
        FnArg[] args;
        while (!p.check(TokenKind.RParen) && !p.isAtEnd())
        {
            Token argName = p.consume(TokenKind.Identifier, "Expected an identifier to argument name.");
            p.consume(TokenKind.Colon, "Expected ':' after argument name.");
            TypeExpr* argType = p.type.parse();
            args ~= FnArg(argName.value.str, argType, false, argName.pos);
            p.match([TokenKind.Comma]);
        }        
        p.consume(TokenKind.RParen, "Expected ')' after function arguments.");
        // p.consume(TokenKind.Arrow, "Expected '->' before function type.");
        TypeExpr* type = TypeExpr.makeNamed("void", Position.init);
        if (p.match([TokenKind.Arrow]))
            type = p.type.parse();

        p.consume(TokenKind.LBRace, "Expected '{' before function body.");
        Node*[] body;
        while (!p.check(TokenKind.RBrace) && !p.isAtEnd())
            body ~= p.parse();
        p.consume(TokenKind.RBrace, "Expected '}' after function body.");

        Node* n = new Node();
        n.kind = NodeKind.FnDecl;
        n.fn.name = name.value.str;
        n.fn.body = body;
        n.fn.args = args;
        n.fn.generics = generics;
        n.typeExpr = type;
        n.pos = name.pos;
        return n;
    }
}
