class AppValidators {
  static final RegExp _regexEmail = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
  );
  static final RegExp _regexPassword = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])');
  static final RegExp _regexTelefonoCellulare = RegExp(r'^\+?[0-9]{9,15}$');
  static final RegExp _regexTelefonoOpzionale = RegExp(r'^\+?[0-9]{5,15}$');
  static final RegExp _regexPIva = RegExp(r'^\d{11}$');
  static final RegExp _regexProvincia = RegExp(r'^[a-zA-Z]{2}$');
  static final RegExp _regexCivico = RegExp(r'^[a-zA-Z0-9\s/]+$');
  static final int _numeroCaratteriPassword = 8;

  static String? validaObbligatorio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obbligatorio';
    }
    return null;
  }

  static String? validaObbligatorioBreve(String? value, String messaggioCorto) {
    if (value == null || value.trim().isEmpty) {
      return messaggioCorto;
    }
    return null;
  }

  static String? validaNomeMinimo(String? value, {int minLength = 3}) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obbligatorio';
    }
    if (value.trim().length < minLength) {
      return 'Deve contenere almeno $minLength caratteri';
    }
    return null;
  }

  static String? validaPartitaIva(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Inserisci la Partita IVA';
    }

    if (!_regexPIva.hasMatch(value.trim())) {
      return 'Deve contenere esattamente 11 numeri';
    }
    return null;
  }

  static String? validaProvincia(String? value) {
    if (value == null || value.trim().length != 2) return 'Err';

    if (!_regexProvincia.hasMatch(value.trim())) {
      return 'Solo lettere';
    }
    return null;
  }

  static String? validaCivico(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'N°';
    }

    if (!_regexCivico.hasMatch(value.trim())) {
      return 'Err';
    }
    return null;
  }

  static String? validaEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Inserisci l\'indirizzo email';
    }
    if (!_regexEmail.hasMatch(value.trim())) {
      return 'Inserisci un\'email valida';
    }
    return null;
  }

  static String? validaTelefonoObbligatorio(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Inserisci il cellulare';
    }
    if (!_regexTelefonoCellulare.hasMatch(value.trim())) {
      return 'Numero non valido (no lettere/spazi)';
    }
    return null;
  }

  static String? validaTelefonoOpzionale(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Essendo opzionale, se vuoto passa
    }
    if (!_regexTelefonoOpzionale.hasMatch(value.trim())) {
      return 'Numero non valido';
    }
    return null;
  }

  static String? validaPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci una password';
    }
    if (value.length < _numeroCaratteriPassword) {
      return 'Deve contenere almeno $_numeroCaratteriPassword caratteri';
    }
    if (!_regexPassword.hasMatch(value)) {
      return 'Inserisci almeno una maiuscola e un numero';
    }
    return null;
  }

  static String? validaPasswordOpzionale(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Se lasciato vuoto, non dà errore
    }
    if (value.length < _numeroCaratteriPassword) {
      return 'Deve contenere almeno $_numeroCaratteriPassword caratteri';
    }
    if (!_regexPassword.hasMatch(value)) {
      return 'Inserisci almeno una maiuscola e un numero';
    }
    return null;
  }

  static String? validaConfermaPassword(
    String? value,
    String passwordRiferimento,
  ) {
    if (value == null || value.isEmpty) {
      return 'Conferma la tua password';
    }
    if (value != passwordRiferimento) {
      return 'Le password non corrispondono';
    }
    return null;
  }
}
