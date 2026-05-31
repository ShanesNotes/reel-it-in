/* =============================================================
   REEL IT IN — Show UI Kit · Live Focus Deck
   The on-air teleprompter overlay. Arrow through sparks, mark
   covered, resize text, throw a wildcard. Mostly-cosmetic.
   ============================================================= */
function FocusDeck({
  open, spark, isWild, index, total, covered, scale,
  onClose, onPrev, onNext, onDot, onCover, onWild, onScale,
}) {
  const centerRef = useRef(null);

  // replay the swap animation whenever the shown spark changes
  useEffect(() => {
    const el = centerRef.current;
    if (!el) return;
    el.classList.remove("anim");
    void el.offsetWidth;
    el.classList.add("anim");
  }, [spark, isWild]);

  if (!spark) return null;

  return (
    <div
      id="focus"
      className={open ? "open" : ""}
      role="dialog"
      aria-label="Spark focus view"
      aria-hidden={!open}
      style={{ "--fscale": scale }}
    >
      <div className="f-top">
        <span className="f-counter">
          {isWild ? <b>WILD</b> : <span><b>{index + 1}</b> / {total}</span>}
        </span>
        <button className="f-close" onClick={onClose}>Esc · back</button>
      </div>

      <div className="f-center" ref={centerRef}>
        <span className="f-tag">{(isWild ? "Wildcard · " : "") + spark.tag}</span>
        <p className="f-prompt">{spark.prompt}</p>
        <p className="f-aside">{spark.aside}</p>
      </div>

      <div className="f-dots">
        {Array.from({ length: total }).map((_, i) => (
          <button
            key={i}
            className={"dot" + (!isWild && i === index ? " active" : "") + (covered.has(i) ? " done" : "")}
            aria-label={"Spark " + (i + 1)}
            onClick={() => onDot(i)}
          ></button>
        ))}
      </div>

      <div className="f-bar">
        <button className={covered.has(index) && !isWild ? "on" : ""} onClick={onCover}>
          {covered.has(index) && !isWild ? "✓ Covered" : "Mark covered"}
        </button>
        <button onClick={onWild}>Wildcard</button>
        <button aria-label="Smaller text" onClick={() => onScale(-0.1)}>A −</button>
        <button aria-label="Larger text" onClick={() => onScale(0.1)}>A +</button>
        <span style={{ fontFamily: "var(--mono)", fontSize: 10, letterSpacing: ".1em", textTransform: "uppercase", color: "var(--fg3)" }}>← → move</span>
      </div>

      <button className="f-chevron f-prev" aria-label="Previous spark" onClick={onPrev}>‹</button>
      <button className="f-chevron f-next" aria-label="Next spark" onClick={onNext}>›</button>
    </div>
  );
}

Object.assign(window, { FocusDeck });
