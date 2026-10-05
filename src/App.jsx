import "./App.css";

function App() {
  return (
    <div className="site">
      {/* NAVBAR */}
      <nav className="navbar">
        <a href="#" className="brand">
          Match<span className="brand-in">In</span>
          <span className="brand-zona">Zona</span>
        </a>

        <div className="nav-links">
          <a href="#scopri">Scopri</a>
          <a href="#giocatori">Giocatori</a>
          <a href="#centri">Centri sportivi</a>
          <a href="#sport">Sport</a>
        </div>

        <a href="#download" className="nav-cta">
          Scarica l'app
        </a>
      </nav>

      {/* HERO */}
      <header className="hero">
        <div className="hero-glow hero-glow-green"></div>
        <div className="hero-glow hero-glow-orange"></div>

        <div className="hero-text">
          <div className="badge">LO SPORT INIZIA DA QUI</div>

          <h1>
            Trova.
            <br />
            Prenota.
            <br />
            <span>Gioca.</span>
          </h1>

          <p>
            Trova campi e partite vicino a te, organizza il tuo prossimo match e
            vivi lo sport in modo più semplice.
          </p>

          <div className="hero-buttons">
            <a href="#scopri" className="btn primary">
              Scopri MatchInZona
            </a>

            <a href="#centri" className="btn secondary">
              Sei un centro sportivo?
            </a>
          </div>
        </div>

        <div className="hero-phone">
          <div className="phone-frame phone-green">
            <img src="/images/1.png" alt="MatchInZona app lato giocatore" />
          </div>
        </div>
      </header>

      {/* SPORT */}
      <section id="sport" className="sports-section">
        <span className="small-title">MULTISPORT</span>

        <div className="sports-list">
          <div className="sport-pill">⚽ Calcio</div>
          <div className="sport-pill">🥎 Tennis</div>
          <div className="sport-pill">🎾 Padel</div>
          <div className="sport-pill">🏀 Basket</div>
          <div className="sport-pill">🏐 Pallavolo</div>
        </div>
      </section>

      {/* PRESENTAZIONE */}
      <section id="scopri" className="intro-section">
        <div className="section-label">MatchInZona</div>

        <h2>
          Un solo posto per trovare
          <span> dove e con chi giocare.</span>
        </h2>

        <p>
          MatchInZona mette insieme giocatori, partite e centri sportivi. Niente
          gruppi infiniti, messaggi sparsi o telefonate per sapere se un campo è
          disponibile.
        </p>

        <div className="steps">
          <div className="step">
            <div className="step-number">01</div>
            <h3>Trova</h3>
            <p>Scopri partite e centri sportivi nella tua zona.</p>
          </div>

          <div className="step">
            <div className="step-number">02</div>
            <h3>Prenota</h3>
            <p>Scegli sport, campo, giorno e orario.</p>
          </div>

          <div className="step">
            <div className="step-number">03</div>
            <h3>Gioca</h3>
            <p>Organizza il tuo match o unisciti ad altri giocatori.</p>
          </div>
        </div>
      </section>

      {/* GIOCATORI */}
      <section id="giocatori" className="showcase showcase-player">
        <div className="showcase-image">
          <div className="phone-frame phone-green">
            <img src="/images/3.png" alt="MatchInZona per giocatori" />
          </div>
        </div>

        <div className="showcase-content">
          <span className="section-label">PER I GIOCATORI</span>

          <h2>
            Il prossimo match
            <span> è già qui.</span>
          </h2>

          <p>
            MatchInZona ti aiuta a trovare partite disponibili vicino a te,
            prenotare campi e conoscere altri giocatori.
          </p>

          <div className="features">
            <div>✓ Match nella tua zona</div>
            <div>✓ Prenotazione campi</div>
            <div>✓ Chat con i partecipanti</div>
            <div>✓ Partite pubbliche e private</div>
          </div>
        </div>
      </section>

      {/* CENTRI SPORTIVI */}
      <section id="centri" className="showcase showcase-manager">
        <div className="showcase-content">
          <span className="section-label orange">PER I CENTRI SPORTIVI</span>

          <h2>
            Più semplice per te.
            <span className="orange-text"> Più facile per loro.</span>
          </h2>

          <p>
            Gestisci campi, disponibilità e prenotazioni da un'unica piattaforma
            e fai conoscere il tuo centro a nuovi giocatori.
          </p>

          <div className="features orange-features">
            <div>✓ Gestione campi e sport</div>
            <div>✓ Orari e disponibilità</div>
            <div>✓ Prenotazioni organizzate</div>
            <div>✓ Maggiore visibilità del centro</div>
          </div>
        </div>

        <div className="showcase-image">
          <div className="phone-frame phone-orange">
            <img src="/images/8.jpg" alt="MatchInZona per centri sportivi" />
          </div>
        </div>
      </section>

      {/* DOWNLOAD */}
      <section id="download" className="download-section">
        <div className="download-glow"></div>

        <span className="section-label">PROSSIMAMENTE</span>

        <h2>Porta lo sport sempre con te.</h2>

        <p>MatchInZona sarà presto disponibile per Android.</p>

        <div className="store-buttons">
          <button className="store-button" disabled>
            <span className="store-icon">▶</span>

            <span>
              <small>PRESTO SU</small>
              Google Play
            </span>
          </button>

          <button className="store-button" disabled>
            <span className="store-icon">●</span>

            <span>
              <small>PROSSIMAMENTE</small>
              App Store
            </span>
          </button>
        </div>

        <div className="availability">● In fase di lancio</div>
      </section>

      {/* FOOTER */}
      <footer>
        <div className="footer-brand">
          Match<span className="brand-in">In</span>
          <span className="brand-zona">Zona</span>
        </div>

        <p>Trova. Prenota. Gioca.</p>

        <div className="footer-links">
          <a href="mailto:matchinzona@gmail.com">Contatti</a>

          <a href="#">Privacy</a>

          <a href="#">Termini e condizioni</a>
        </div>

        <div className="copyright">
          © 2026 MatchInZona. Tutti i diritti riservati.
        </div>
      </footer>
    </div>
  );
}

export default App;
