/**
 * @file Implements browser-specific functionality.
 */

class Posix {
  open() {
    throw WebAssembly.RuntimeError("Unsupported rts interface: open");
  }
  close() {
    throw WebAssembly.RuntimeError("Unsupported rts interface: close");
  }
  fstat() {
    throw WebAssembly.RuntimeError("Unsupported rts interface: fstat");
  }
}

export default {
  /**
   * A custom Time interface, used in {@link TimeCBits}.
   */
  Time: {
    /**
     * Returns the current timestamp, where 0 represents
     * the time origin of the document.
     * @returns A [seconds, nanoseconds] Array.
     */
    getCPUTime: () => {
      const ms = performance.now(),
            s = Math.floor(ms / 1000.0),
            ns = Math.floor(ms - s * 1000) * 1000000;
      return [s, ns];
    },
    /**
     * Returns the current timestamp, where 0 represents UNIX Epoch.
     * @returns A [seconds, nanoseconds] Array.
     */
    getUnixEpochTime: () => {
      const ms = Date.now(),
            s = Math.floor(ms / 1000.0),
            ns = Math.floor(ms - s * 1000) * 1000000;
      return [s, ns];
    },
    /**
     * The resolution of the timestamps in nanoseconds.
     * Note! Due to the Spectre attack, browsers do not
     * provide high-resolution timestamps anymore.
     * See https://developer.mozilla.org/en-US/docs/Web/API/Performance/now
     * and https://spectreattack.com.
     * We fallback to a resolution of 1ms.
     */
    resolution: 1000000
  },
  posix: Posix
};
