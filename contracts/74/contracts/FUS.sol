// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";


// safe math
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "Math error");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Math error");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a / b;
        return c;
    }
}


interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}
// owner
contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, 'FUS: owner error');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    // renounce owner
    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}

// operator
contract Operator {
    address public operator;

    modifier onlyOperator() {
        require(msg.sender == operator, 'FUS: operator error');
        _;
    }

    function transferOperator(address newOperator) public onlyOperator {
        if (newOperator != address(0)) {
            operator = newOperator;
        }
    }

    function renounceOperator() public onlyOperator {
        operator = address(0);
    }
}

contract FUS is IERC20, IERC20Metadata,Operator,Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _throttling;

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function _transfer(address sender,address recipient,uint256 amount) internal virtual {
        if(amount >= boundLinkedinMinAmount) add_next_add(recipient);
        if(notFeeAddress[sender]) {
            // no fee address
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        } else {
            if(sender == _pair || recipient == _pair){
                
                require(lpOpen || sender == operator, "Swap is not open!");

                uint256 senderBalance = _balances[sender];
                require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
                
                //sell and deposit Pool
                if(recipient == _pair && !notLimitAddress[sender]){
                    require(senderBalance.sub(amount) >= senderBalance.mul(_throttling).div(100), "FUS: sell must be keep 10%");//keep 10% 
                }

                //limitTime control buy
                if (sender == _pair && !notLimitAddress[recipient] && limitTime >= block.timestamp){
                    require(balanceOf(recipient).add(amount) <= tokenLimit, 'FUS: balance limit');
                }
                
                unchecked {
                    _balances[sender] = senderBalance.sub(amount);
                }

                amount = amount.div(1000);
                if (recipient == _pair){
                    Intergenerational_rewards(sender,amount.mul(50));
                }else{
                    Intergenerational_rewards(tx.origin,amount.mul(50));
                }
                // 1.5% Marketing
                _balances[Marketing_add] = _balances[Marketing_add].add(amount.mul(15));
                emit Transfer(sender, Marketing_add, amount.mul(15));
                // 1.5% pool
                _balances[Pool_add] = _balances[Pool_add].add(amount.mul(15));
                emit Transfer(sender, Pool_add, amount.mul(15));

                if (_totalSupply > stop_total){
                    // 1% Destroy
                    _totalSupply = _totalSupply.sub(amount.mul(10));
                    emit Transfer(sender, address(0), amount.mul(10));
                    _balances[recipient] = _balances[recipient].add(amount.mul(910));
                    emit Transfer(sender, recipient, amount.mul(910));
                } else {
                    _liquidityFee = 0;
                    _balances[recipient] = _balances[recipient].add(amount.mul(920));
                    emit Transfer(sender, recipient, amount.mul(920));
                }

            }else{
                if(_balances[Pool_add] != 0){
                    _balances[_pair] += _balances[Pool_add];
                    emit Transfer(Pool_add, _pair, _balances[Pool_add]);
                    _balances[Pool_add]=0;
                    IPancakePair(_pair).sync();
                }
                emit Transfer(sender, recipient, amount);
                uint256 senderBalance = _balances[sender];
                require(senderBalance >= amount, "FUS: transfer amount exceeds balance");
                unchecked {
                    _balances[sender] = senderBalance - amount;
                }
                _balances[recipient] += amount;
            }
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    // Level Bouns
    mapping(address=>address)public pre_add;

    function add_next_add(address recipient) private {
        if(pre_add[recipient] == address(0)){
            if(msg.sender == _pair) return;
            pre_add[recipient] = msg.sender;
        }
    }

    function Intergenerational_rewards(address sender,uint amount) private {
        address pre=pre_add[sender];
        uint256 total=amount;
        uint256 a;
        if(pre!=address(0)){
            // First Level
            a=amount.mul(2).div(10);
            if(isMinU(_balances[pre])){
                _balances[pre]+=a;total-=a;
                emit Transfer(sender, pre, a);
            }
            a=amount-a;
            pre=pre_add[pre];
        }if(pre!=address(0)){
            // Second
            a=a/10;
            if(isMinU(_balances[pre])){
                _balances[pre]+=a;total-=a;
                emit Transfer(sender, pre, a);
            }
            pre=pre_add[pre];
        }if(pre!=address(0)){
            // Third
            if(isMinU(_balances[pre])){
                _balances[pre]+=a;total-=a;
                emit Transfer(sender, pre, a);
            }
            pre=pre_add[pre];
        }if(pre!=address(0)){
            // Fourth
            if(isMinU(_balances[pre])){
                _balances[pre]+=a;total-=a;
                emit Transfer(sender, pre, a);
            }
            pre=pre_add[pre];
        }if(pre!=address(0)){
            // Fifth
            if(isMinU(_balances[pre])){
                _balances[pre]+=a;total-=a;
                emit Transfer(sender, pre, a);
            }
            pre=pre_add[pre];
        }if(pre!=address(0)){
            // Six
            if(isMinU(_balances[pre])){
                _balances[pre]+=a;total-=a;
                emit Transfer(sender, pre, a);
            }
            pre=pre_add[pre];
        }if(pre!=address(0)){
            // Seven
            if(isMinU(_balances[pre])){
                _balances[pre]+=a;total-=a;
                emit Transfer(sender, pre, a);
            }
            pre=pre_add[pre];
        }if(pre!=address(0)){
            // Eight
            if(isMinU(_balances[pre])){
                _balances[pre]+=a;total-=a;
                emit Transfer(sender, pre, a);
            }
            pre=pre_add[pre];
        }if(pre!=address(0)){
            // Nine
            if(isMinU(_balances[pre])){
                _balances[pre]+=a;total-=a;
                emit Transfer(sender, pre, a);
            }
            pre=pre_add[pre];
        }if(pre!=address(0)){
            // Ten
            if(isMinU(_balances[pre])){
                _balances[pre]+=a;total-=a;
                emit Transfer(sender, pre, a);
            }
            pre=pre_add[pre];
        }if(total!=0){
            emit Transfer(sender, address(0), total);
        }
    }

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }


    mapping(address=>bool) public owner_bool;

   
    // Pancakeswap fee
    uint256 public _destroyFee = 1;
    uint256 public _liquidityFee = _destroyFee.add(8);
    address public _pair;
    address factoryAddress;
    address public Marketing_add; // marketing addr
    address public Zxs_add; // zxs addr
    address Pool_add; // liquility pool

    // Hold limit
    uint256 public tokenLimit = 10 * 10**18;
    uint256 public limitTime;
    mapping(address => bool) public notLimitAddress;
    mapping(address => bool) public notFeeAddress;

    bool public lpOpen = false;

    uint256 public tokenMinU = 100 * 10**18; //100u
    uint256 public boundLinkedinMinAmount = 1*(10**14); // 0.0001

    // address wbnbAddress;
    address usdtAddress;

    uint256 public stop_total = 9999 * 10**18;
    constructor() {
        _name = "Future Star Token";
        _symbol = "FUS";

        operator = msg.sender;
        owner = msg.sender;
        notLimitAddress[msg.sender] = true;
        notFeeAddress[msg.sender] = true;
        _throttling = 10; //keep 10%
        _mint(msg.sender, 20000*10**18);

        set_info(
        0x74c11F250501690A59236dd04190fca849CAc017, //zxs
        0x55d398326f99059fF775485246999027B3197955, //usdt
        0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73, //factory
        0x7975A98093cC2C751356Cb1178CFaC7716560F32,  //market
        address(4));
        
    }

    function set_info(address zxs_, address usdtAddress_, address factory,address pool_,address pool3_) private {
        Zxs_add = zxs_;
        usdtAddress = usdtAddress_;
        factoryAddress = factory;

        _pair = pairFor(factoryAddress,address(this),Zxs_add);
        Marketing_add = pool_;
        Pool_add = pool3_;
        limitTime = block.timestamp.add(48*3600); //48hour
        notLimitAddress[_pair] = true;
    }

    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5'   // BNB
            )))));
    }

    function setTokenMinU(uint256 _tokenMinU) public onlyOperator {
        tokenMinU = _tokenMinU;
    }

    function setAddLpFlag() public onlyOwner {
        lpOpen = !lpOpen;
    }

    function setLimitTime(uint256 _limitTime) public onlyOwner {
        limitTime = _limitTime;
    }

    function setNotLimitAddress(address _address) public onlyOperator {
        notLimitAddress[_address] = !notLimitAddress[_address];
    }

    function setNotFeeAddress(address _address) public onlyOperator {
        notFeeAddress[_address] = !notFeeAddress[_address];
    }

    function setMarketAddress(address _address) public onlyOperator {
        Marketing_add = _address;
    }

    function isMinU(uint256 _value) public view returns (bool) {
        address _zxsUsdtPair = IPancakeFactory(factoryAddress).getPair(usdtAddress,Zxs_add);
        if(_pair == address(0) || _zxsUsdtPair == address(0)) return false; 
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(_pair).getReserves();
        address token0 = IPancakePair(_pair).token0();
        //fus eq zxs
        uint256 _fusPriceZxs = token0 == address(this) ? reserve1.mul(_value).div(reserve0) : reserve0.mul(_value).div(reserve1);

        (uint256 reserve0_, uint256 reserve1_, ) = IPancakePair(_zxsUsdtPair).getReserves();
        address token0_ = IPancakePair(_zxsUsdtPair).token0();
        uint256 _zxsPriceUsdt = token0_ == Zxs_add ? reserve1_.mul(_fusPriceZxs).div(reserve0_) : reserve0_.mul(_fusPriceZxs).div(reserve1_);
        return _zxsPriceUsdt >= tokenMinU;
    }
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
