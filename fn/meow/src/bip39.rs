use rand::prelude::IndexedRandom;

lazy_static::lazy_static! {
    pub static ref WORDLIST: Vec<&'static str> = std::include_str!("english.txt").split('\n').filter(|s| !s.is_empty()).collect();
}

/// generate a mnemonic of length `len`, separated by hyphen
pub fn mnemonic(len: usize) -> String {
    WORDLIST
        .choose_multiple(&mut rand::rng(), len)
        .copied()
        .collect::<Vec<&str>>()
        .join("-")
}
