use serde::{Deserialize, Serialize};
use num_traits::Float;

// #[repr(C)]
#[derive(Clone,Serialize, Deserialize,Debug)]
pub(crate) struct Options<T:Float> {
    stock_p:T,
    strike_p:T,
    exp_time:T,
    rf_rate:T,
    vol:T
}

// #[repr(C)]
#[derive(Clone,Serialize,Deserialize,Debug)]
struct Bonds<T>{
    c_rate:T,
    f_val:T,
    curr_val:T,
    maturity:T,
}

impl<T:Float> Bonds<T>{}

impl<T:Float> Options<T>{
    pub fn new(stock_p:T,strike_p:T,exp_time:T,rf_rate:T,vol:T)->Self{
        Options{
            stock_p,
            strike_p,
            exp_time,
            rf_rate,
            vol
        }
    }
}