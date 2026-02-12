module frontend.types.type_expr;

import frontend.lexer.tokens;
import frontend.parser.ast;
import std.stdio;

struct NamedTypeExpr
{
    string name;
    void print()
    {
        writeln("NamedTypeExpr: ", name);        
    }
}

struct PointerTypeExpr
{
    TypeExpr* base;
    void print()
    {
        writeln("PointerTypeExpr: ", *base);        
    }
}

enum TypeExprKind : ubyte {
    Named,
    Pointer,
}

struct TypeExpr
{
    TypeExprKind kind;
    Position pos;
    union {
        NamedTypeExpr named;
        PointerTypeExpr pointer;
    }

    string toStr()
    {
        if (kind == TypeExprKind.Named)
            return this.named.name;
        if (kind == TypeExprKind.Pointer)
            return this.pointer.base.toStr() ~ "*";
        return "<undefined>";
    }

    static TypeExpr* makeNamed(string name, Position pos)
    {
        TypeExpr* type = new TypeExpr();
        type.kind = TypeExprKind.Named;
        type.named.name = name;
        type.pos = pos;
        return type;
    }

    static TypeExpr* makePointer(TypeExpr* base)
    {
        TypeExpr* type = new TypeExpr();
        type.kind = TypeExprKind.Pointer;
        type.pointer.base = base;
        type.pos = base.pos;
        return type;
    }
}
