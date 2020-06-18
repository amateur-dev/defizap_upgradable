# Zapout Balancer pool contracts

These contracts are used to get ETH or ERC20 token from balancer pool tokens

## Balancer Unzap

This contract have 2 public  methods:

### EasyZapOut:
1. Takes ERC token address, amount of BPT and balancer pool address
2. If given token bounded to given pool, it uses this token to zapout
3. Else it uses getBestDeal method to select the token, zapout with it and then swaps to the desired token.

### ZapOut:
1. Takes ERC token address, user address, amount of BPT to zapout,  balancer pool address and intermediate token address
2. If given token bounded, it zapout with this token
3. Else zapout with intermediate token first and then convert it to the desired token

## Difference between v1 and v2:

1. V1 takes single intermediate token while V2 takes array of tokens with their proportion.

2. V1 selects intermediate token which gives max value in ETH after zapout while V2 selects the token having max uniswap exchange contract balance. 

> V1.1 contract is with a private method which is called by both the public methods to avoid the non reentrancy issue 