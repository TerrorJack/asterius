import module from "./rtsapi.wasm.mjs";
import rtsapi from "./rtsapi.lib.mjs";

process.on("unhandledRejection", err => { throw err; });

module.then(m => rtsapi(m)).then(i => {
    i.exports.hs_init();
    i.exports.main();
    i.exports.rts_evalLazyIO(i.exports.rts_apply(i.symbolTable.Main_printInt_closure, i.exports.rts_apply(i.symbolTable.Main_fact_closure, i.exports.rts_mkInt(5))));
    const tid_p1 = i.exports.rts_eval(i.exports.rts_apply(i.symbolTable.Main_fact_closure, i.exports.rts_mkInt(5)));
    console.log(i.exports.rts_getInt(i.exports.getTSOret(tid_p1)));
    console.log(i.exports.rts_getBool(i.symbolTable.ghczmprim_GHCziTypes_False_closure));
    console.log(i.exports.rts_getBool(i.symbolTable.ghczmprim_GHCziTypes_True_closure));
    console.log(i.exports.rts_getBool(i.exports.rts_mkBool(0)));
    console.log(i.exports.rts_getBool(i.exports.rts_mkBool(42)));
    const x0 = Math.random();
    const tid_p3 = i.exports.rts_eval(i.exports.rts_apply(i.symbolTable.base_GHCziBase_id_closure, i.exports.rts_mkDouble(x0)));
    const x1 = i.exports.rts_getDouble(i.exports.getTSOret(tid_p3));
    console.log([x0, x1, x0 === x1]);
});
