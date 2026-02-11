module backend.qbe.qbe;

import std.stdio;
import std.conv;
import std.array;
import std.string;
import std.algorithm;

enum QBEType
{
    Word, // w - 32 bits
    Long, // l - 64 bits

    Single, // s - float 32 bits
    Double, // d - double 64 bits

    Byte, // b - para memória
    Halfword, // h - para memória
}

enum TypeClass
{
    Regular,
    Aggregate,
}

enum Linkage
{
    Private, // function/data local ao arquivo
    Public, // export
    Section, // section "name"
    Thread, // thread
}

enum StorageClass
{
    Auto, // temporary
    Global, // global data
    Thread, // thread-local
}

class QBEValue
{
    string name;
    QBEType type;

    this(string name, QBEType type = QBEType.Long)
    {
        this.name = name;
        this.type = type;
    }

    override string toString() const
    {
        return name;
    }

    string typedString() const
    {
        return typePrefix(type) ~ " " ~ name;
    }
}

class QBETemp : QBEValue
{
    this(string name, QBEType type = QBEType.Long)
    {
        super("%" ~ name, type);
    }
}

class QBEGlobal : QBEValue {
    this(string name, QBEType type = QBEType.Long)
    {
        super("$" ~ name, type);
    }
}

class QBEConst : QBEValue
{
    long value;

    this(long value, QBEType type = QBEType.Long)
    {
        super(value.to!string, type);
        this.value = value;
    }
}

class QBEFloatConst : QBEValue
{
    double value;

    this(double value, QBEType type = QBEType.Double)
    {
        super(doubleToQBE(value), type);
        this.value = value;
    }

    private static string doubleToQBE(double d)
    {
        if (d != d)
            return "d_nan"; // NaN
        if (d == double.infinity)
            return "d_inf";
        if (d == -double.infinity)
            return "d_-inf";
        return format("d_%a", d);
    }
}

class QBESingleConst : QBEValue
{
    float value;

    this(float f)
    {
        super(floatToQBE(f), QBEType.Single);
        this.value = f;
    }

    private static string floatToQBE(float f)
    {
        if (f != f)
            return "s_nan";
        if (f == float.infinity)
            return "s_inf";
        if (f == -float.infinity)
            return "s_-inf";
        return format("s_%a", f);
    }
}

abstract class QBEInstr
{
    abstract string emit();
}

class QBEAssign : QBEInstr
{
    QBETemp result;
    string op;
    QBEType type;
    QBEValue[] args;

    this(QBETemp result, string op, QBEType type, QBEValue[] args...)
    {
        this.result = result;
        this.op = op;
        this.type = type;
        this.args = args.dup;
    }

    override string emit()
    {
        auto argStr = args.map!(a => a.toString()).join(", ");
        return format("    %s =%s %s %s",
            result.name, typePrefix(type), op, argStr);
    }
}

class QBEVolatile : QBEInstr
{
    string op;
    QBEValue[] args;

    this(string op, QBEValue[] args...)
    {
        this.op = op;
        this.args = args.dup;
    }

    override string emit()
    {
        auto argStr = args.map!(a => a.toString()).join(", ");
        return format("    %s %s", op, argStr);
    }
}

class QBELabel : QBEInstr
{
    string name;

    this(string name)
    {
        this.name = name;
    }

    override string emit()
    {
        return "@" ~ name;
    }
}

class QBEJump : QBEInstr
{
    string target;

    this(string target)
    {
        this.target = target;
    }

    override string emit()
    {
        return "    jmp @" ~ target;
    }
}

class QBEJnz : QBEInstr
{
    QBEValue cond;
    string ifTrue;
    string ifFalse;

    this(QBEValue cond, string ifTrue, string ifFalse)
    {
        this.cond = cond;
        this.ifTrue = ifTrue;
        this.ifFalse = ifFalse;
    }

    override string emit()
    {
        return format("    jnz %s, @%s, @%s", cond, ifTrue, ifFalse);
    }
}

class QBEReturn : QBEInstr
{
    QBEValue value;

    this(QBEValue value = null)
    {
        this.value = value;
    }

    override string emit()
    {
        if (value)
            return format("    ret %s", value.toString());
        return "    ret";
    }
}

class QBECall : QBEInstr
{
    QBETemp result; // pode ser null para void
    QBEType retType;
    QBEValue func;
    QBEValue[] args;

    this(QBETemp result, QBEType retType, QBEValue func, QBEValue[] args...)
    {
        this.result = result;
        this.retType = retType;
        this.func = func;
        this.args = args.dup;
    }

    override string emit()
    {
        string argStr = args.map!(a => a.typedString()).join(", ");
        if (result)
            return format("    %s =%s call %s(%s)",
                result.name, typePrefix(retType), func, argStr);
        return format("    call %s(%s)", func, argStr);
    }
}

class QBEAlloc : QBEInstr
{
    QBETemp result;
    QBEType _align;
    long size;

    this(QBETemp result, long size, QBEType _align = QBEType.Long)
    {
        this.result = result;
        this.size = size;
        this._align = _align;
    }

    override string emit()
    {
        return format("    %s =%s alloc%s %d",
            result.name, typePrefix(QBEType.Long),
            typePrefix(_align), size);
    }
}

class QBEStore : QBEInstr
{
    QBEType type;
    QBEValue value;
    QBEValue addr;

    this(QBEType type, QBEValue value, QBEValue addr)
    {
        this.type = type;
        this.value = value;
        this.addr = addr;
    }

    override string emit()
    {
        return format("    store%s %s, %s",
            typePrefix(type), value, addr);
    }
}

class QBELoad : QBEInstr
{
    QBETemp result;
    QBEType type;
    QBEValue addr;

    this(QBETemp result, QBEType type, QBEValue addr)
    {
        this.result = result;
        this.type = type;
        this.addr = addr;
    }

    override string emit()
    {
        return format("    %s =%s load%s %s",
            result.name, typePrefix(type), typePrefix(type), addr);
    }
}

class QBECompare : QBEInstr
{
    QBETemp result;
    string cmpOp; // eq, ne, slt, sle, sgt, sge, ult, ule, ugt, uge
    QBEType type;
    QBEValue left;
    QBEValue right;

    this(QBETemp result, string cmpOp, QBEType type, QBEValue left, QBEValue right)
    {
        this.result = result;
        this.cmpOp = cmpOp;
        this.type = type;
        this.left = left;
        this.right = right;
    }

    override string emit()
    {
        return format("    %s =w c%s%s %s, %s",
            result.name, cmpOp, typePrefix(type), left, right);
    }
}

class QBECast : QBEInstr
{
    QBETemp result;
    QBEType fromType;
    QBEType toType;
    QBEValue value;

    this(QBETemp result, QBEType toType, QBEType fromType, QBEValue value)
    {
        this.result = result;
        this.fromType = fromType;
        this.toType = toType;
        this.value = value;
    }

    override string emit()
    {
        string castOp = getCastOp(fromType, toType);
        return format("    %s =%s %s %s",
            result.name, typePrefix(toType), castOp, value);
    }

    private string getCastOp(QBEType from, QBEType to)
    {
        // Conversões inteiras
        if (from == QBEType.Word && to == QBEType.Long)
            return "extsw";
        if (from == QBEType.Long && to == QBEType.Word)
            return "copy"; // truncate

        // Int -> Float
        if ((from == QBEType.Word || from == QBEType.Long) && to == QBEType.Single)
            return "swtof";
        if ((from == QBEType.Word || from == QBEType.Long) && to == QBEType.Double)
            return "sltof";

        // Float -> Int
        if (from == QBEType.Single && to == QBEType.Word)
            return "stosi";
        if (from == QBEType.Double && to == QBEType.Long)
            return "dtosi";

        // Float -> Float
        if (from == QBEType.Single && to == QBEType.Double)
            return "exts";
        if (from == QBEType.Double && to == QBEType.Single)
            return "truncd";

        return "copy";
    }
}

class QBEPhi : QBEInstr
{
    QBETemp result;
    QBEType type;
    string[QBEValue] incoming; // value -> label

    this(QBETemp result, QBEType type)
    {
        this.result = result;
        this.type = type;
    }

    void addIncoming(QBEValue value, string label)
    {
        incoming[value] = label;
    }

    override string emit()
    {
        auto pairs = incoming.byKeyValue()
            .map!(kv => format("@%s %s", kv.value, kv.key))
            .join(", ");
        return format("    %s =%s phi %s",
            result.name, typePrefix(type), pairs);
    }
}

class QBEBlock
{
    string name;
    QBEInstr[] instructions;

    this(string name)
    {
        this.name = name;
    }

    void add(QBEInstr instr)
    {
        instructions ~= instr;
    }

    string emit()
    {
        auto app = appender!string();
        app ~= "@" ~ name ~ "\n";
        foreach (instr; instructions)
        {
            app ~= instr.emit() ~ "\n";
        }
        return app.data;
    }
}

struct QBEParam
{
    QBEType type;
    string name;

    string toString() const
    {
        return typePrefix(type) ~ " %" ~ name;
    }
}

class QBEFunction
{
    string name;
    QBEType returnType;
    QBEParam[] params;
    QBEBlock[] blocks;
    Linkage linkage;
    bool isVariadic;
    bool exported;

    this(string name, QBEType returnType = QBEType.Long,
        Linkage linkage = Linkage.Private)
    {
        this.name = name;
        this.returnType = returnType;
        this.linkage = linkage;
    }

    void addParam(QBEType type, string name)
    {
        params ~= QBEParam(type, name);
    }

    void addBlock(QBEBlock block)
    {
        blocks ~= block;
    }

    QBEBlock createBlock(string name)
    {
        auto block = new QBEBlock(name);
        addBlock(block);
        return block;
    }

    string emit()
    {
        auto app = appender!string();

        // Linkage
        if (exported || linkage == Linkage.Public)
            app ~= "export ";
        else if (linkage == Linkage.Section)
            app ~= "section ";
        else if (linkage == Linkage.Thread)
            app ~= "thread ";

        app ~= format("function %s $%s(", typePrefix(returnType), name);
        app ~= params.map!(p => p.toString()).join(", ");

        if (isVariadic)
            app ~= ", ...";

        app ~= ") {\n";

        foreach (block; blocks)
            app ~= block.emit();

        app ~= "}\n";
        return app.data;
    }
}

struct QBEDataItem
{
    QBEType type;
    QBEValue value;

    string toString() const
    {
        return typePrefix(type) ~ " " ~ value.toString();
    }
}

class QBEData
{
    string name;
    Linkage linkage;
    QBEDataItem[] items;
    size_t _align;
    bool exported;

    this(string name, Linkage linkage = Linkage.Private, size_t _align = 0)
    {
        this.name = name;
        this.linkage = linkage;
        this._align = _align;
    }

    void addByte(long value)
    {
        items ~= QBEDataItem(QBEType.Byte, new QBEConst(value, QBEType.Byte));
    }

    void addHalf(long value)
    {
        items ~= QBEDataItem(QBEType.Halfword, new QBEConst(value, QBEType.Halfword));
    }

    void addWord(long value)
    {
        items ~= QBEDataItem(QBEType.Word, new QBEConst(value, QBEType.Word));
    }

    void addLong(long value)
    {
        items ~= QBEDataItem(QBEType.Long, new QBEConst(value, QBEType.Long));
    }

    void addString(string str)
    {
        foreach (char c; str)
            addByte(cast(long) c);
        addByte(0); // null terminator
    }

    void addZeros(size_t count)
    {
        items ~= QBEDataItem(QBEType.Byte, new QBEConst(cast(long) count));
    }

    string emit()
    {
        auto app = appender!string();

        if (exported || linkage == Linkage.Public)
            app ~= "export ";
        else if (linkage == Linkage.Section)
            app ~= "section ";
        else if (linkage == Linkage.Thread)
            app ~= "thread ";

        app ~= format("data $%s = ", name);

        if (_align > 0)
            app ~= format("align %d ", _align);

        app ~= "{ ";
        app ~= items.map!(item => item.toString()).join(", ");
        app ~= " }\n";

        return app.data;
    }
}

struct QBETypeField
{
    QBEType type;
    size_t count; // 1 para escalar, >1 para array

    string toString() const
    {
        if (count > 1)
            return format("%s %d", typePrefix(type), count);
        return typePrefix(type);
    }
}

class QBEAggregate
{
    string name;
    QBETypeField[] fields;
    size_t _align;
    bool opaque; // tipo opaco (sem layout definido)

    this(string name, size_t _align = 0, bool opaque = false)
    {
        this.name = name;
        this._align = _align;
        this.opaque = opaque;
    }

    void addField(QBEType type, size_t count = 1)
    {
        fields ~= QBETypeField(type, count);
    }

    string emit()
    {
        auto app = appender!string();
        app ~= format("type :%s = ", name);

        if (opaque)
            app ~= "{ 0 }";
        else
        {
            if (_align > 0)
                app ~= format("align %d ", _align);
            app ~= "{ ";
            app ~= fields.map!(f => f.toString()).join(", ");
            app ~= " }";
        }

        app ~= "\n";
        return app.data;
    }
}

class QBEModule
{
    QBEAggregate[] types;
    QBEData[] dataSegments;
    QBEFunction[] functions;

    void addType(QBEAggregate type)
    {
        types ~= type;
    }

    void addData(QBEData data)
    {
        dataSegments ~= data;
    }

    void addFunction(QBEFunction func)
    {
        functions ~= func;
    }

    string emit()
    {
        auto app = appender!string();

        app ~= "# Generated by QBE Backend for D\n\n";

        if (types.length > 0)
        {
            app ~= "# Types\n";
            foreach (type; types)
                app ~= type.emit();
            app ~= "\n";
        }

        // Dados
        if (dataSegments.length > 0)
        {
            app ~= "# Data\n";
            foreach (data; dataSegments)
                app ~= data.emit();
            app ~= "\n";
        }

        // Funções
        if (functions.length > 0)
        {
            app ~= "# Functions\n";
            foreach (func; functions)
            {
                app ~= func.emit();
                app ~= "\n";
            }
        }

        return app.data;
    }

    void writeToFile(string filename)
    {
        auto f = File(filename, "w");
        f.write(emit());
        f.close();
    }
}

class QBEBuilder
{
    QBEModule module_;
    QBEFunction currentFunction;
    QBEBlock currentBlock;
    int tempCounter;
    int blockCounter;

    this()
    {
        module_ = new QBEModule();
    }

    QBETemp temp(QBEType type = QBEType.Long)
    {
        return new QBETemp(format("t%d", tempCounter++), type);
    }

    string uniqueBlockName()
    {
        return format("L%d", blockCounter++);
    }

    QBEFunction startFunction(string name, QBEType retType = QBEType.Long)
    {
        currentFunction = new QBEFunction(name, retType);
        module_.addFunction(currentFunction);
        tempCounter = 0;
        blockCounter = 0;
        return currentFunction;
    }

    QBEBlock startBlock(string name = null)
    {
        if (name is null)
            name = uniqueBlockName();
        currentBlock = new QBEBlock(name);
        currentFunction.addBlock(currentBlock);
        return currentBlock;
    }

    void emit(QBEInstr instr)
    {
        currentBlock.add(instr);
    }

    QBETemp add(QBEType type, QBEValue a, QBEValue b)
    {
        auto result = temp(type);
        emit(new QBEAssign(result, "add", type, a, b));
        return result;
    }

    QBETemp sub(QBEType type, QBEValue a, QBEValue b)
    {
        auto result = temp(type);
        emit(new QBEAssign(result, "sub", type, a, b));
        return result;
    }

    QBETemp mul(QBEType type, QBEValue a, QBEValue b)
    {
        auto result = temp(type);
        emit(new QBEAssign(result, "mul", type, a, b));
        return result;
    }

    QBETemp div(QBEType type, QBEValue a, QBEValue b)
    {
        auto result = temp(type);
        emit(new QBEAssign(result, "div", type, a, b));
        return result;
    }

    QBETemp rem(QBEType type, QBEValue a, QBEValue b)
    {
        auto result = temp(type);
        emit(new QBEAssign(result, "rem", type, a, b));
        return result;
    }

    QBETemp and(QBEType type, QBEValue a, QBEValue b)
    {
        auto result = temp(type);
        emit(new QBEAssign(result, "and", type, a, b));
        return result;
    }

    QBETemp or(QBEType type, QBEValue a, QBEValue b)
    {
        auto result = temp(type);
        emit(new QBEAssign(result, "or", type, a, b));
        return result;
    }

    QBETemp xor(QBEType type, QBEValue a, QBEValue b)
    {
        auto result = temp(type);
        emit(new QBEAssign(result, "xor", type, a, b));
        return result;
    }

    QBETemp cmp(string op, QBEType type, QBEValue a, QBEValue b)
    {
        auto result = temp(QBEType.Word);
        emit(new QBECompare(result, op, type, a, b));
        return result;
    }

    QBETemp alloc(long size, QBEType _align = QBEType.Long)
    {
        auto result = temp(QBEType.Long);
        emit(new QBEAlloc(result, size, _align));
        return result;
    }

    void store(QBEType type, QBEValue value, QBEValue addr)
    {
        emit(new QBEStore(type, value, addr));
    }

    QBETemp load(QBEType type, QBEValue addr)
    {
        auto result = temp(type);
        emit(new QBELoad(result, type, addr));
        return result;
    }

    QBETemp call(QBEType retType, QBEValue func, QBEValue[] args...)
    {
        auto result = temp(retType);
        emit(new QBECall(result, retType, func, args));
        return result;
    }

    void callVoid(QBEValue func, QBEValue[] args...)
    {
        emit(new QBECall(null, QBEType.Long, func, args));
    }

    void ret(QBEValue value = null)
    {
        emit(new QBEReturn(value));
    }

    void jmp(string target)
    {
        emit(new QBEJump(target));
    }

    void jnz(QBEValue cond, string ifTrue, string ifFalse)
    {
        emit(new QBEJnz(cond, ifTrue, ifFalse));
    }

    QBEModule getModule()
    {
        return module_;
    }
}

string typePrefix(QBEType type)
{
    final switch (type)
    {
    case QBEType.Word:
        return "w";
    case QBEType.Long:
        return "l";
    case QBEType.Single:
        return "s";
    case QBEType.Double:
        return "d";
    case QBEType.Byte:
        return "b";
    case QBEType.Halfword:
        return "h";
    }
}

