+++
title = "Rust Akıllı İşaretçiler"
description = "Rust Akıllı İşaretçileri üzerine notlar"
date = "2022-02-16"
draft = false
[taxonomies]
tags = ["rust", "turkish"]
+++

## Akıllı İşaretçiler (Smart Pointers) Nedir

Aslında bunlar normal işaretçilerden çok da farklı değiller sadece işaret ettikleri veriye ek olarak üst veriler taşıyorlar. Örnek olarak
[String](https://doc.rust-lang.org/std/string/struct.String.html) tipini ele alalım bu tip bir byte dizisini tutmasının yanı sıra uzunluk ve kapasite bilgilerini de tutar, genel olarak akıllı işaretçilerin normal işaretçilerden farkı budur.


## [Box&lt;T&gt;](https://doc.rust-lang.org/std/boxed/index.html) Akıllı İşaretçisi

Verileri stack yerine [heap](https://scribe.rip/yigit-xcodeproj/stack-ve-heap-arasindaki-fark-nedir-stack-vs-heap-c61e3d463dd7) üzerinde tutar. Aslında bu tipin çok da artıları yoktur

-   Tutmak istediğiniz verinin boyutunun derleme anında bilinmediği durumlarda
-   Kopyalamak istemediğiniz büyük miktarda verinin sahipliğini değiştirmek istediğiniz durumlarda kullanılabilir.

Kullanımı:

```rust
fn main() {
    let b = Box::new(5);
    println!("b = {}", b);
}
```

şeklindedir. Eğer C/C++ bilginiz varsa heap üzerinde tuttuğumuz veriyi free tarzı bir yapı kullanarak neden deallocate etmediğimizi sorabilirsiniz, bunun sebebi Rust'ın değişken kapsam dışına çıktığında hem heap üzerindeki veriyi hem de stack üzerindeki heap'teki verinin adresini tutan pointerı otomatik olarak silmesidir.


## [Rc&lt;T&gt;](https://doc.rust-lang.org/std/rc/index.html) Akıllı İşaretçisi

Bir verinin birden fazla sahibi olduğu durumlarda kullanılır tutulan veri her klonlandığında referans sayısı bir artar ve tüm referanslar yok olduğunda tutulan veri silinir. Rc&lt;T&gt; tipini aile odasındaki bir TV olarak hayal edin, biri içeri girip TV izlemek istediğinde televizyonu açar ve diğerleri de odaya gelip televizyon izleyebilir ama son kişi de odadan çıkıcağında televizyonu kapatır çünkü artık kullanımda değildir değil mi? işte Rc&lt;T&gt; tipi de tam olarak bunu yapar.

```rust
use std::rc::Rc;

fn main() {
    let a = Rc::new(1);
    println!("a'nın başlangıçtaki referans sayısı = {}", Rc::strong_count(&a));
    let _b = Rc::clone(&a);
    println!("b'den sonra referans sayısı = {}", Rc::strong_count(&a));
    {
        let _c = Rc::clone(&a);
        println!("c'den sonra referans sayısı = {}", Rc::strong_count(&a));
    }
    println!("c kapsam dışına çıktıktan sonra referans sayısı = {}", Rc::strong_count(&a));
}
```

Kendi bilgisayarınızda bu örnek kodu deneyerek Rc'nin nasıl işlediğini daha iyi anlayabilirsiniz.

Not: Rc&lt;T&gt; tipini sadece tek threadlı uygulamalarda kullanabilirsiniz diğerleri için [Arc](https://doc.rust-lang.org/std/sync/struct.Arc.html) yardımınıza koşar.


## [RefCell&lt;T&gt;](https://doc.rust-lang.org/std/cell/index.html) Akıllı İşaretçisi

RefCell'i anlatmadan önce biraz Interior mutability nedir diye bahsetmek gerekiyor. Interior mutability, mutable bir referansınız olmayan bir veriyi değiştirmeye izin veren bir tasarım desenidir normalde bu işlem Rust'ın kurallarına aykırıdır ama Cell&lt;T&gt; ve RefCell&lt;T&gt; tipleri sayesinde bunu yapabiliyoruz.

RefCell kullanırken dikkat etmeniz gereken şey borrowing kurallarının derleme zamanında değil de çalışma zamanında yakalandığını unutmamaktır bu hataları fark etmeyi zorlaştırabilir bu yüzden gerçekten ihtiyacınız olmadığında RefCell yerine Cell kullanmak daha mantıklıdır.
Aşağıdaki örnek programa bakalım:

```rust
fn main() {
    let x = 5;
    let y = &mut x;
}
```

mutable olarak belirlenmeyen bir değişkene mutable bir referans almaya çalıştığımızı anlayan derleyici kodu reddetti peki şunu deneyelim:

```rust
use std::cell::RefCell;
fn main() {
    let x = RefCell::new(5);
    let mut y = x.borrow_mut();
    println!("değiştirmeden önce x'in değeri = {}",*y);
    *y = 10;
    println!("değiştirdikten sonra x'in değeri = {}",*y);
}
```

çalıştı değil mi? işte interior mutability budur. Bu deseni örneğin sizi &amp;self almaya zorlayan traitlerde selfi RefCell olarak tanımlayarak kullanabilirsiniz.


## Kaynaklar {#kaynaklar}

-   <https://doc.rust-lang.org/book/ch15-00-smart-pointers.html>
