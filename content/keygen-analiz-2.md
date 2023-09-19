+++
title = "Keygen Analizi - Bölüm 2"
description = "Bir keygeni IDA Pro ve x64dbg ile analiz edip Rust ile baştan yazıyoruz - Bölüm 2"
date = "2022-09-11"
draft = false
[taxonomies]
tags = ["reversing", "turkish"]
+++

## Giriş
Lütfen [önceki](https://usdogu.github.io/posts/keygen-analiz-1/) bölümü okumadan bu bölüme geçmeyiniz.
Sadece keygeni istiyorsanız: https://codeberg.org/usdogu/httpdebuggerpro-keygen

Bu bölümde önceki bölümde edindiğimiz bilgileri kullanarak keygeni Rust ile baştan yazmaya çalışıcaz.
Projeyi açmak ve bağımlılıkları eklemek için;
```sh
cargo new httpdebugger_keygen
cargo add winreg # kayıt defteri ile işlem yapabilmek için
cargo add winsafe # C diskinin seri numarasını almamızı sağlayan Windows fonksiyonuna erişmek için
cargo add rand # Rastgele sayı üretmek için
```

## Koda Dalış
Öncelikle bağımlılıkları kullanalım;
```rust
use rand::{thread_rng, Rng};
use winreg::RegKey;
use winsafe::GetVolumeInformation;
```

## Http Debugger Versiyonunu Çekme
```rust
pub fn get_httpdebugger_version() -> Result<u32, Box<dyn std::error::Error>> {
    let hkcu = RegKey::predef(winreg::enums::HKEY_CURRENT_USER);
    let (regkey, _) = hkcu.create_subkey("Software\\MadeForNet\\HTTPDebuggerPro")?;
    let version_full: String = regkey.get_value("AppVer")?;
    let mut version = version_full
        .split_whitespace()
        .last()
        .expect("There's an error while reading the Http Debugger version")
        .to_string();
    version.retain(|c| c != '.'); // remove dots from the version number

    Ok(version.parse()?)
}
```
Burada çok da bi olay yok aslında öncelikle HKEY_CURRENT_USER altındaki Software\\MadeForNet\\HTTPDebuggerPro "subkey"inin içindeki AppVer değerini alıyor daha sonra ise boşluk ile ayırıp son değeri alıyor sonra ise buradan son değeri alıyor yani 

"HTTP Debugger 9.0.0.12" -> ["HTTP", "Debugger", "9.0.0.12"] -> "9.0.0.12" oluyor.
Bir sonraki satırda ise nokta karakteri olmayan karakterleri tutup noktaları siliyor "9.0.0.12" değeri "90012" oluyor.

## Kayıt Defteri İsmini Üretme
```rust
pub fn create_registry_key_name(
    httpdebugger_version: u32,
) -> Result<String, Box<dyn std::error::Error>> {
    let mut serial_number = u32::default();

    GetVolumeInformation(
        Some("C:\\"),
        None,
        Some(&mut serial_number),
        None,
        None,
        None,
    )?;
    let result = format!(
        "SN{}",
        httpdebugger_version ^ ((!serial_number >> 1) + 736) ^ 0x590D4
    );

    Ok(result)
}
```

Burada ise GetVolumeInformation kullanarak C diskinin seri numarasını serial_number değişkenine yazıyoruz daha sonra ise orijinal versiyondaki bit işlemlerini aynen uygulayıp gelen değeri döndürüyoruz.

## Lisans Üretme
```rust
pub fn create_license_key() -> String {
    let mut rng = thread_rng();
    let rand1: u8 = rng.gen();
    let rand2: u8 = rng.gen();
    let rand3: u8 = rng.gen();
    format!(
        "{:02X}{:02X}{:02X}7C{:02X}{:02X}{:02X}{:02X}",
        rand1,
        rand2 ^ 0x7c,
        !rand1,
        rand2,
        rand3,
        rand3 ^ 7,
        rand1 ^ !rand3
    )
}
```
Burası da orijinal kodun tamamen kopyası, 3 adet 0 ile 255 arası rastgele değer oluşturuyoruz (u8 = unsigned char = 0-255 arası değer) yalnız dikkatli bir okuyucuysanız ~ yerine ! kullandığımı farketmişsinizdir bunun sebebi Rust'da bit bazlı NOT operatörünün ~ yerine ! olması.


## Değeri Kayıt Defterine Yazma
```rust
pub fn write_to_registry(
    registry_key_name: &str,
    license_key: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let hkcu = RegKey::predef(winreg::enums::HKEY_CURRENT_USER);
    let (regkey, _) = hkcu.create_subkey("Software\\MadeForNet\\HTTPDebuggerPro")?;
    regkey.set_value(registry_key_name, &license_key.to_string())?;

    Ok(())
}
```
Bunda da çok açıklamaya gerek yok argüman olarak kayıt defteri için ismi ve lisans anahtarını alıyor ve Software\\MadeForNet\\HTTPDebuggerPro içine yazıyor


## Main Fonksiyonu
```rust
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let version = get_httpdebugger_version()?;
    let license_key = create_license_key();
    let registry_key_name = create_registry_key_name(version);
    write_to_registry(&registry_key_name, &license_key);
    println!("Cracked");
    Ok(())
}
```

## Çıkış
Şimdilik bu kadardı ufak bir GUI eklenmiş halini görmek isterseniz gönderinin başındaki git deposuna bakabilirsiniz, iyi günler dilerim