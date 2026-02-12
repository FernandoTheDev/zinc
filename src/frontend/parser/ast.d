module frontend.parser.ast;

import frontend.types.type_expr;
import frontend.lexer.tokens : Position, TokenKind;

enum NodeKind : ubyte
{
    Program,
    Identifier,

    VarDecl,
    FnDecl,

    BinaryExpr,
    CallExpr,
    UnaryExpr,

    NumberLit,
    FloatLit,
    DoubleLit,
    BoolLit,
    StringLit,
    NullLit,

    ReturnStmt,
}

struct Program
{
    Node[] body;
}

enum FnAttributes : uint
{
    MustUse = 1 << 0,
    Inline = 1 << 1,
    NoInline = 1 << 2,
    Unused = 1 << 3,
    Weak = 1 << 4,
    Section = 1 << 5,
    NoReturn = 1 << 6,
    Pure = 1 << 7,
    Cold = 1 << 8,
    Hot = 1 << 9,
    Export = 1 << 10,
    Comptime = 1 << 11,
}

struct FnArg
{
    string name;
    TypeExpr* typeExpr;
    // Type type;
    bool varargs;
    Position pos;
}

struct FnDecl
{
    string name;
    FnArg[] args;
    Node*[] body;
    TypeExpr*[] generics;
    uint flags;
    uint align_;
    string section;
}

struct VarDecl
{
    string name;
    Node* value;
}

struct ReturnStmt
{
    Node* val;
}

struct NumberLit
{
    long val;
}

struct DoubleLit
{
    double val;
}

struct FloatLit
{
    float val;
}

struct Identifier
{
    string val;
}

struct BinaryExpr
{
    Node* left, right;
    TokenKind op;
}

struct CallExpr
{
    string name;
    Node*[] args;
    TypeExpr*[] generics;
}

struct UnaryExpr
{
    Node* val;
    TokenKind op;
    bool post;
}

struct Node
{
    NodeKind kind;
    TypeExpr* typeExpr;
    // Type type;
    Position pos;
    union
    {
        Program prog;
        FnDecl fn;
        VarDecl var;
        ReturnStmt ret;
        NumberLit number;
        DoubleLit doubleLit;
        FloatLit floatLit;
        Identifier id;
        BinaryExpr binary;
        CallExpr call;
        UnaryExpr unary;
    }
}
