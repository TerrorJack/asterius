// Block allocator. This hands out blocks to the heap, and internally uses
// the megablock allocator to allocate memory. For more information, see:
// https://gitlab.haskell.org/ghc/ghc/wikis/commentary/rts/storage/block-alloc
// https://gitlab.haskell.org/ghc/ghc/blob/master/rts/sm/BlockAlloc.c
// https://gitlab.haskell.org/ghc/ghc/blob/master/includes/rts/storage/Block.h
//
//
// First, some terminology:
// megablock: large unit of allocation of *blocks*
// block group: smallest unit of allocation. there is a "block descriptor", 
//        and a chunk of memory which is the "block memory", which is allocated
//        in multiple of `block_size.
//        The block descriptor points to the block memory.
//        Block descriptors of all blocks in a megablock are at the beginning
//        of a megablock.
// mega-group: collection of megablocks. Block descriptor for the mega
//             group is in the first megablock.
//
//
// Data structures:
// ----------------
//
// We have a map of blocks and megablocks, mapping number of blocks/megablocks requested
// to the free blocks/megablocks of that size.
//
// Allocation
// ----------
//
// If allocation size is strictly less than a megablock (ie, it will fit in
// a megablock):
//     - Look through blockgroupfree for a block group of that size, and provide it
//     - Split the block in the block free if there is extra space.
//     - Otherwise, allocate a megablock, split the megablock into the
//       allocation and the leftover free blocks.
//
//  If the allocation size is greater than a megablock:
//    - Look through the megagroup free for a megablock of that size.
//      If it does not exist, then create a new megagrup.
//
// Freeing
// -------
//
// When we free things, we might find that during the process of freeing, we can
// recover entire megablocks, and not just blocks. To find this, we will need
// to coalesce adjacent blocks to check if they form a megablock.
import * as rtsConstants from "./rts.constants.mjs";
import { Memory } from "./rts.memory.mjs";
import * as assert from "assert";

function ptr2bdescr(p) {
    // #define BLOCK_MASK (BLOCK_SIZE-1)
    // #define MBLOCK_MASK (MBLOCK_SIZE-1)
    // #define Bdescr(p) \
    // ((((p) &  MBLOCK_MASK & ~BLOCK_MASK) >> (BLOCK_SHIFT-BDESCR_SHIFT)) | ((p) & ~MBLOCK_MASK))
    const BLOCK_MASK = BigInt(rtsConstants.block_size - 1);
    const MBLOCK_MASK = BigInt(rtsConstants.mblock_size - 1);
    const BLOCK_SHIFT = BigInt(rtsConstants.block_shift);
    const BDESCR_SHIFT = BigInt(rtsConstants.bdescr_shift);

    // console.log(`BLOCK_MASK: ${BLOCK_MASK} | MBLOCK_MASK: ${MBLOCK_MASK} | BLOCK_SHIFT: ${BLOCK_SHIFT} | BDESCR_SHIFT: ${BDESCR_SHIFT}`);
    p = BigInt(p);
    return Number((((p) &  MBLOCK_MASK & ~BLOCK_MASK) >> (BLOCK_SHIFT-BDESCR_SHIFT)) | ((p) & ~MBLOCK_MASK));
}

// given a pointer, return the megablock to which it belongs to
function ptr2mblock(p) {
  const MBLOCK_MASK = BigInt(rtsConstants.mblock_size - 1);
  return Number(p & MBLOCK_MASK);
}

// return the megablock a block descriptor belongs to
function bdescr2megablock(bd) {
  const MBLOCK_MASK = BigInt(rtsConstants.mblock_size - 1);
  return Number(BigInt(bd) & MBLOCK_MASK);
}

// get the count of bdescr in the megablock.
// 0 if it is the first bdescr
// 1 if it is the second bdescr
// etc
function bdescr2index(bd) {
  const base = bdescr2megablock(bd);
  assert.equal((bd - base) % rtsConstants.sizeof_bdescr, 0);
  return (bd - base) / rtsConstants.sizeof_bdescr;
}

// check that a megablock is correctly aligned
function assertMblockAligned(mb) {
  const n = Math.log2(rtsConstants.mblock_size);
  assert.equal((BigInt(mb) >> BigInt(n)) << BigInt(n), BigInt(mb));
}

// check that a block descriptor is correctly aligned
function assertBdescrAligned(bd) {
  assertMblockAligned(bd - rtsConstants.offset_first_bdescr);
}


export class BlockAlloc {
  constructor() {
    this.memory = undefined;
    this.staticMBlocks = undefined;
    this.capacity = undefined;
    this.size = undefined;
    // contains (l, r) of the free block groups.
    this.freeBlockGroups = [];
    Object.seal(this);
  }

  init(memory, static_mblocks) {
    this.memory = memory;
    this.staticMBlocks = static_mblocks;
    this.capacity = this.memory.buffer.byteLength / rtsConstants.mblock_size;
    this.size = this.capacity;
  }


  allocMegaBlocks(n) {
    if (this.size + n > this.capacity) {
      const d = Math.max(n, this.capacity);
      this.memory.grow(d * (rtsConstants.mblock_size / rtsConstants.pageSize));
      this.capacity += d;
    }
    const prev_size = this.size;
    this.size += n;
    return Memory.tagData(prev_size * rtsConstants.mblock_size);
  }

  // low level initialization function to initialize a block descriptor
  initBdescr(bd, block_addr, nblocks) {
    this.memory.i64Store(bd + rtsConstants.offset_bdescr_start, block_addr);
    this.memory.i64Store(bd + rtsConstants.offset_bdescr_free, block_addr);
    this.memory.i64Store(bd + rtsConstants.offset_bdescr_link, 0);
    this.memory.i32Store(bd + rtsConstants.offset_bdescr_blocks, nblocks);
  }

  // return a block with req_blocks if it exists.
  // INVARIANT: req_blocks < blocks_per_mblock.
  // returns a block descriptor if exists, 
  // returns undefined otherwise
  lookupFreeBlockGroupBdescr(req_blocks) {
    assert(req_blocks < rtsConstants.blocks_per_mblock);
    for(let i = 0; i < this.freeBlockGroups.length; ++i) {
      const [l, r] = this.freeBlockGroups[i];
      const nblocks = (r - l) / this.block_size;
      // we don't have enough blocks, continue
      if (nblocks < req_blocks) continue;

      const bd = ptr2bdescr(l);
      this.initBdescr(bd, k, req_blocks);

      // allow splicing off a smaller block.
      if (req_blocks < nblocks) {
        const rest_l = l + rtsConstants.block_size * req_blocks;
        this.freeBlockGroups.splice(i, [rest_l, r]);
      }
      else {
        this.freeBlockGroups.splice(i);
      }
      return bd;

    } // end oop
  } // end funciion

  allocBlocks(req_blocks) {
    const req_mblocks = Math.ceil(req_blocks / rtsConstants.blocks_per_mblock);
    // We need memory larger than a megablock. Just allocate it.
    if (req_mblocks > 0) {
      const mblock = this.allocMegaBlocks(req_mblocks);
      const bd = mblock + rtsConstants.offset_first_bdescr;
      const block_addr = mblock + rtsConstants.offset_first_block;
      this.initBdescr(bd, block_addr, req_blocks);
    }

    assert.equal(req_mblocks, 0);
    assert.equal(req_blocks < rtsConstants.blocks_per_mblock, true);

    const bd_free = this.lookupFreeBlockGroupBdescr(req_blocks);

    // if we do have a free block, return it.
    if (bd_free) {
      return bd_free;
    }

    // we don't have a free block group. Create a new megablock with those
    // many block groups, and return it.
    const mblock = this.allocMegaBlocks(req_mblocks);
    const bd = mblock + rtsConstants.offset_first_bdescr;
    const block_addr = mblock + rtsConstants.offset_first_block;
    this.initBdescr(bd, block_addr, req_blocks);

    // if we have some free blocks, add that to the free list.
    if (req_blocks < rtsConstants.blocks_per_mblock) {
      const rest_l = block_addr + rtsConstants.block_size * req_blocks;
      const rest_r = block_addr + rtsConstants.block_size * blocks_per_mblock;
    }

  }

  coalesceFreeBlockGroups() {
  }

  freeBlockGroup(i, l_end, r) {
    if (l_end < r) {
      this.memory.memset(l_end, 0x42 + i, r - l_end);
      this.freeBlockGroups.push([l_end, r]);
    }

    coalesceFreeBlockGroups();
  }

  preserveGroups(bds) {
    console.log("preserveGroups:");
    console.log(`bds: ${Array.from(bds)}`);
    bds = Array.from(bds);

    var m = new Map();
    for(var i = 0; i < bds.length; ++i) {
      console.log(`--- ${i}: bds[${i}] = ${bds[i]}`);
      const mblock =  bdescr2megablock(bds[i]);
      if(m.has(mblock)) {
        m[mblock].push(bds[i]);
      } else {
        m[mblock] = [bds[i]];
      }
    }
    
    // current index passed to freeBlockGroup
    let ix = 0;
    
    let sorted_megablocks = Array.from(m.keys()).sort((m0, m1) => m0 - m1);
    // we are allowed to take up an entire megablock if the megablock is free.
    for(var i = 0; i < sorted_megablocks.length; ++i) {
      const mblock = sorted_megablocks[i];
      const bds = m[mblock];
      for(let j = 0; j < bds; ++j) {
        const bd = bds[j];
        const l = this.memory.i64Load(bd + rtsConstants.offset_bdescr_start);
        const nblocks = this.memory.i64Load(bd + rtsConstants.offset_bdescr_blocks);
        const r = l + rtsConstants.block_size * nblocks;
        this.freeBlockGroup(ix++, l, r);
      }
    }
  }
}
