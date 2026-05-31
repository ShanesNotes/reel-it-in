/* =============================================================
   REEL IT IN — Show UI Kit · presentational components
   Small, reusable, mostly-cosmetic recreations of the show's
   building blocks. Exported to window for the app to compose.
   ============================================================= */
const { useState, useEffect, useRef, useCallback } = React;

/* ---- fixed chrome ---- */
function Status({ label = "Pilot", clock = "00:00" }) {
  return (
    <div className="status">
      <span className="dot"></span>
      <span className="lbl-draft">Working Draft · <b>{label}</b></span>
      <span className="lbl-live">On Air</span>
      <span className="clock">{clock}</span>
    </div>
  );
}

function LiveToggle({ live, onToggle }) {
  return (
    <button className="live-toggle" aria-pressed={live} onClick={onToggle}>
      <span className="glyph"></span>
      <span>{live ? "Exit Live" : "Live Mode"}</span>
    </button>
  );
}

/* ---- header blocks ---- */
function Kicker({ children }) {
  return <div className="kicker rise d1">{children}</div>;
}

function ShowTitle() {
  return <h1 className="title rise d2">Reel<span className="it"> It</span> In</h1>;
}

function Deck({ children }) {
  return <p className="deck rise d3">{children}</p>;
}

function Epigraph({ quote, cite }) {
  return (
    <div className="epigraph rise d4">
      <q>{quote}</q>
      <cite>{cite}</cite>
    </div>
  );
}

function Meta({ you, dad, number, label, date }) {
  return (
    <div className="meta rise d5">
      <span className="byline">Hosted by <span className="fill">{you}</span> &amp; <span className="fill">{dad}</span></span>
      <span className="pip"></span><span>Episode {number}</span>
      <span className="pip"></span><span>{label}</span>
      <span className="pip"></span><span>{date}</span>
    </div>
  );
}

/* ---- section scaffold ---- */
function ActHead({ roman, title, note }) {
  return (
    <div className="act-head rise">
      <div className="roman">{roman}</div>
      <div>
        <div className="act-title">{title}</div>
        {note && <div className="act-note">{note}</div>}
      </div>
    </div>
  );
}

function Lede({ first, children }) {
  return <p className={"lede rise" + (first ? " first" : "")}>{children}</p>;
}

/* ---- news ---- */
function NewsCard({ source, headline, why, url }) {
  return (
    <article className="news-card rise">
      <span className="src">{source}</span>
      <h3 className="head">{headline}</h3>
      <p className="why"><b>Why it matters:</b> {why}</p>
      {url && <a className="read" href={url} target="_blank" rel="noopener">Read the story <span className="arr">→</span></a>}
    </article>
  );
}

function NewsBlank({ onClick }) {
  return (
    <div className="news-card blank rise" onClick={onClick}>
      <span>+ drop this week's story</span>
    </div>
  );
}

/* ---- sparks ---- */
function Spark({ id, index, tag, prompt, aside, covered, live, onCover, onOpen }) {
  return (
    <div
      className={"spark rise" + (covered ? " covered" : "")}
      data-id={id}
      onClick={() => live && onOpen(index)}
    >
      <span className="idx">{String(index + 1).padStart(2, "0")}</span>
      <span
        className="cover"
        role="button"
        aria-label="Mark covered"
        title="Mark covered"
        onClick={(e) => { e.stopPropagation(); onCover(id); }}
      >{covered ? "✓" : ""}</span>
      <span className="tag">{tag}</span>
      <p className="prompt">{prompt}</p>
      <p className="aside">{aside}</p>
    </div>
  );
}

/* ---- archive ---- */
function ArcRow({ number, title, tags, date }) {
  return (
    <div className="arc-row rise">
      <div className="arc-num">EP {number}</div>
      <div>
        <div className="arc-title">{title}</div>
        <div className="arc-tags">{tags}</div>
      </div>
      <div className="arc-date">{date}</div>
    </div>
  );
}

function Footer() {
  return (
    <footer>
      <p><span className="gold">Reel It In</span> — working title, working draft</p>
      <p>Template · duplicate weekly · edit the EPISODE block · archive the rest</p>
    </footer>
  );
}

Object.assign(window, {
  Status, LiveToggle, Kicker, ShowTitle, Deck, Epigraph, Meta,
  ActHead, Lede, NewsCard, NewsBlank, Spark, ArcRow, Footer,
});
