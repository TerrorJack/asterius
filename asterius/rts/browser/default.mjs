/**
 * @file Implements browser-specific functionality.
 */
export default {
  /**
   * The Performance Web API.
   */
  Performance: window.performance,
  /**
   * A custom Time interface, used in {@link TimeCBits}.
   */
  Time: {
    /**
     * Returns the current millisecond timestamp,
     * where 0 represents the time origin of the document.
     */
    now: () => {
      return performance.now();
    },
    /**
     * Returns the current millisecond timestamp,
     * where 0 represents UNIX Epoch. The output is a
     * [seconds, nanoseconds] Array.
     */
    time: () => {
      const ms = Date.now(),
            s = Math.floor(ms / 1000.0),
            ns = Math.floow(ms - s * 1000) * 1000000;
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
  }
};
