use rand::seq::SliceRandom;

lazy_static::lazy_static! {
    static ref WORDLIST: Vec<&'static str> = std::include_str!("english.txt").split('\n').collect();
}

/// generate a mnemonic of length `len`, separated by hyphen
pub fn mnemonic(len: usize) -> String {
    WORDLIST
        .choose_multiple(&mut rand::thread_rng(), len)
        .copied()
        .collect::<Vec<&str>>()
        .join("-")
}
