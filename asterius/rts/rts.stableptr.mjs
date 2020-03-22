export class StablePtrManager {
  constructor() {
    this.spt = new Map();
    this.lasts = [0, 0];
    Object.freeze(this);
  }

  newWithTag(v, tag) {
    const sp = (++this.lasts[tag] << 1) | tag;
    this.spt.set(sp, v);
    return sp;
  }

  newStablePtr(addr) {
    return this.newWithTag(addr, 0);
  }

  deRefStablePtr(sp) {
    return this.spt.get(sp);
  }

  freeStablePtr(sp) {
    this.spt.delete(sp);
  }

  newJSVal(v) {
    return this.newWithTag(v, 1);
  }

  getJSVal(sp) {
    return this.deRefStablePtr(sp);
  }

  setJSVal(sn0, sn1) {
    this.spt.set(sn0, this.getJSVal(sn1));
  }

  moveJSVal(sn0, sn1) {
    this.setJSVal(sn0, sn1);
    this.freeJSVal(sn1);
  }

  freeJSVal(sp) {
    this.freeStablePtr(sp);
  }

  hasStablePtr(sp) {
    return this.spt.has(sp);
  }

  preserveJSVals(sps) {
    for (const sp of Array.from(this.spt.keys()))
      if (sp & 1 && !sps.has(sp)) this.freeJSVal(sp);
  }
}
