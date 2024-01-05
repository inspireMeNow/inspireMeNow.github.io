---
title: rust学习
ZHtags:
  - rust
key: rust-learning
date: '2022-07-27'
lastmod: '2022-07-27'
---

1.rust函数

```rust
fn main(){ //主函数
 println!("hello world!");
}
```

2.Rust变量
Rust 是强类型语言，但具有自动判断变量类型的能力。  
声明变量使用let关键字。  
重影:指变量的名称可以被重新使用。  
有符号类型  

| 长度     | 有符号   | 无符号   |
| ------ | ----- | ----- |
| 8bit   | i8    | u8    |
| 16bit  | i16   | u16   |
| 32bit  | i32   | u32   |
| 64bit  | 164   | u64   |
| 128bit | i128  | u128  |
| arch   | isize | usize |