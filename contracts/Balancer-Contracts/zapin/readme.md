# ZapIn Balancer pool contracts 

These contracts are used to invest into balancer pool with either ETH or ERC20 token

## Balancer ZapIn General

### EasyZapIn:
1. Takes ETH (address(0x00)) or ERC token address, amount and balancer pool address and ETH as msg.value if needed
2. If given address is token and bounded to pool, it uses this token to zapin
3. Else it uses getBestDeal method to select the token, swaps to that token and zapin with it.

### ZapIn:
1. Takes ERC token address or ETH (address(0x00)), user address, amount of ERC to invest,  balancer pool address and intermediate token address and ETH as msg.value if needed 
2. If token is given which is bounded, it zaps in with token
3. Else first ETH/ERC20 to given intermediate token and then uses it for zapin.

## ERC balancer

### EasyZapIn:
1. Takes ERC token address, amount and balancer pool address
2. If given token bounded to given pool, it uses this token to zapin
3. Else it uses getBestDeal method to select the token, swaps to that token and zapin with it.

### ZapIn:
1. Takes ERC token address, user address, amount of ERC to invest,  balancer pool address and intermediate token address
2. If given token bounded, it zapin with given token
3. Else first convert it to given intermediate token and then uses it for zapin.

## ETH balancer

### EasyZapIn:
1. Takes ether and balancer pool address
2. If given token bounded to given pool, it uses this token to zapin
3. Else it uses getBestDeal method to select the token, swaps to that token and zapin with it.

### ZapIn:
1. Takes intermediate user address, Ethers to invest,  balancer pool address and intermediate token address
2. First convert eth to given intermediate token and then uses it for zapin.

## Difference between v1 and v2:

1. V1 takes single intermediate token while V2 takes array of tokens with their proportion.

2. V1 select intermediate token which returns max BPT after zapout while V2 selects the one having max uniswap exchange balance. 

> V1.1 contract is with a private method which is called by both the public methods to avoid the non reentrancy issue 