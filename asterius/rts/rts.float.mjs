// Implements primitives from primFloat.c
export class FloatCBits {
    constructor(memory) {
        this.memory  = memory;
        /* Constants copy-pasted by running this C program:
        #include <float.h>
        #include <stdio.h>

        #define PRINT(name) printf("this." #name " = %d;\n", name);
        int main() {
            PRINT(FLT_MIN_EXP); PRINT(FLT_MANT_DIG);
            PRINT(DBL_MIN_EXP); PRINT(DBL_MANT_DIG);
            return 0;
        }
        Other code copy-pasted from C calculations.
        */


        this.FLT_MIN_EXP = -125;
        this.FLT_MANT_DIG = 24;
        this.DBL_MIN_EXP = -1021;
        this.DBL_MANT_DIG = 53;

        this.MY_DMINEXP = ((this.DBL_MIN_EXP) - (this.DBL_MANT_DIG) - 1);
        /* DMINEXP is defined in values.h on Linux (for example) */
        this.DHIGHBIT = 0x00100000;
        this.DMSBIT = 0x80000000;

        this.MY_FMINEXP = ((this.FLT_MIN_EXP) - (this.FLT_MANT_DIG) - 1);
        this.FHIGHBIT = 0x00800000;
        this.FMSBIT = 0x80000000;

        // buffer of 8 bytes to hold floats/doubles
        this.buffer = new ArrayBuffer(8);
        this.view = new DataView(this.buffer);

        Object.seal(this);
    }

    // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/is
    isFloatNegativeZero(x) {
        return Object.is(-0, x);
    }

    isFloatNaN(x) {
        return x != x;
    }
    isFloatInfinite(x) {
        return !isFinite(x);
    }

    // Does it really make sense to have two functions?  probably not...
    isDoubleNegativeZero(x) {
        return Object.is(-0, x);
    }

    FloatToIEEE(f) {
        this.view.setFloat32(0, f);
        return this.view.getUint32(0);
    }

    IEEEToFloat(ieee) {
        this.view.setUint32(0, ieee);
        return this.view.getFloat32(0);
    }


    __decodeFloat_Int(manp, expp, f) {
        // https://github.com/ghc/ghc/blob/610ec224a49e092c802a336570fd9613ea15ef3c/rts/StgPrimFloat.c#L215
        var man, exp;
        var high = this.FloatToIEEE(f);


        if ((high & ~this.FMSBIT) == 0) {
            man = 0;
            exp = 0;
        } else {
            exp = ((high >> 23) & 0xff) + this.MY_FMINEXP;
            var sign = high;

            high &= this.FHIGHBIT-1;
            if (exp != this.MY_FMINEXP) /* don't add hidden bit to denorms */
                high |= this.FHIGHBIT;
            else {
                exp += 1;
                /* A denorm, normalize the mantissa */
                while (! (high & this.FHIGHBIT)) {
                    high <<= 1;
                    exp -= 1;
                }
            }

            man = high;
            if (sign < 0) {
                man = - man;
            }
        }

        console.log("man: ", man);
        console.log("exp: ", exp);

        this.memory.i64Store(manp, man);
        this.memory.i64Store(expp, exp);
        
        console.log("wrote man, exp");
    }
}
