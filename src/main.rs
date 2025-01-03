mod lib;
use lib::Options;
use std::fs::File;
use std::io::{Read, Write};
use std::process::Command;

fn main() ->Result<(),std::io::Error> {
    let mut opt_vec=vec![];

    for i in 0..=10{
        let opt=Options::new(i as f64,i as f64,i as f64,i as f64,i as f64);
        opt_vec.push(opt);
    }
    let serial_opt=serde_json::to_string_pretty(&opt_vec)?;

    let output = Command::new("./black_scholes_calc")
        .output()
        .expect("Failed to execute CUDA program");

    if !output.status.success() {
        eprintln!("CUDA program failed with error: {}", String::from_utf8_lossy(&output.stderr));
        return Err(std::io::Error::new(std::io::ErrorKind::Other, "CUDA program execution failed"));
    }
    println!("CUDA program output: {}", String::from_utf8_lossy(&output.stdout));

    Ok(())
}
