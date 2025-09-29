# addition module
## compute
u = x + e_1
v = y + msg_poly + e_2

## Behavior
- state machine diagram that add 2 polynomial together 5 times

## components
- ### Carry look ahead adders
    - each compute 1 coeff + 1 coeff
    - reuse one set of 256 cla_adders
- ### MUX
    - Choose input to feed cla_adder
    - Use state of state machine as selector

handle overflow manually
