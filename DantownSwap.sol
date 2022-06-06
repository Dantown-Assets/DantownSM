// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


/// @notice ERC20 interface

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}



/// @notice the uniswap router interface
interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

/// @notice the uniswap pair interface

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

/// @notice the uniswap factory interface
interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}



contract DantownSwap {

    using SafeMath for uint256;

    // 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee - busd
    // 0x64544969ed7EBf5f083679233325356EbE738930 -usdc
    // 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd - wbnb
    // 0xa35062141Fa33BCA92Ce69FeD37D0E8908868AAe - mock cake
    
  
    /// @notice uniswap router address
    address private constant UNISWAP_V2_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    
    /// @notice wrapped BNB address
    address private constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    /// @notice default pair(BUSD) address
    address private defaultPair = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
    
    /// @notice admin/contract owner address
    address admin;

    /// @notice re-entrancy lock params
    bool internal locked;

    /// @notice Dantown commision charge
    uint256 public commisionfee = 0.5 ether;

    /// @notice admin modifier
    modifier onlyAdmin {
    require(msg.sender == admin, "Only admin can call function.");
    _;
    }

    /// @notice Re-entrancy guard
    modifier noReentrant() {
    require(!locked, "No re-entrancy.");
    locked = true;
    _;
    locked = false;
    }

    /// @notice events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
    constructor() {
    admin = msg.sender;
    
    }

    
    /// @notice allows contact to recieve ether/transfers
    receive() external payable {}

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable {}

    /// @notice returns contract owner address
    function owner() public view returns (address) {
    return admin;
    }

    /**
     * @notice fetch contract balance
     * @param token the specific token contract address 
     */
    function getBalance(address token) public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice change contract owner
     * @param newOwner_ the new owner wallet address 
     */
    function transferOwnership( address newOwner_ ) public virtual onlyAdmin() {
    require( newOwner_ != address(0), "new owner is the zero address");
    emit OwnershipTransferred( admin, newOwner_ );
    admin = newOwner_;
    }

    /**
     * @notice change default swap pair
     * @param newPair_ the new pair address 
     */
    function changeDefaultPair( address newPair_ ) public virtual onlyAdmin() {
    require( newPair_ != address(0), "new pair is the zero address");
    defaultPair = newPair_;
    }
    
    /**
     * @notice token swap function
     * @param _tokenOut the recieving token address
     * @param _amountIn the amount inputed
     * @param _amountOutMin the amount of token to be recieved by swap
     * @param _to the wallet address to recieve swap token 
     */
   function Swap(address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address _to) external {
    
    require(_to != address(0), "cant send to the zero address");

    uint256 _finalAmount = _amountIn - ( commisionfee / 100);
    
    IERC20(defaultPair).approve(UNISWAP_V2_ROUTER, _finalAmount);

    address[] memory path;
    if (defaultPair == WBNB || _tokenOut == WBNB) {
      path = new address[](2);
      path[0] = defaultPair;
      path[1] = _tokenOut;
    } else {
      path = new address[](3);
      path[0] = defaultPair;
      path[1] = WBNB;
      path[2] = _tokenOut;
    }
       
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(_finalAmount, _amountOutMin, path, _to, block.timestamp);
    }
    
    
    /**
     * @notice swap token path function
     * @param _tokenOut the recieving token address
     * @param _amountIn the amount inputed
     * @param _tokenIn the token address to be swaped in 
     */ 
    function getAmountOutMin(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {
     
        address[] memory path;
        if (_tokenIn == WBNB || _tokenOut == WBNB) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WBNB;
            path[2] = _tokenOut;
        }
        
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_amountIn, path);
        return amountOutMins[path.length -1];  
    }  

    /**
     * @notice swap quotation function
     * @param _tokenOut the recieving token address
     * @param _amountIn the amount inputed
     * @param _tokenIn the token address to be swaped in 
     */ 
    function getQuote(address _tokenIn, address _tokenOut, uint256 _amountIn) external view returns (uint256) {

        uint256 _finalAmount = _amountIn - ( commisionfee / 100);

        address[] memory path;
        if (_tokenIn == WBNB || _tokenOut == WBNB) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WBNB;
            path[2] = _tokenOut;
        }
        
        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER).getAmountsOut(_finalAmount, path);
        return amountOutMins[path.length -1];  
    } 

    /**
     * @notice withdraw function
     * @param token the token to be withdrawn address 
     */
    function withdrawFunds(address token) public noReentrant onlyAdmin {

    uint256 _amount =  IERC20(token).balanceOf(address(this));

    IERC20(token).approve(msg.sender, _amount);
      
    IERC20(token).transfer(msg.sender,  _amount);
   
    }


    /**
     * @notice send token function
     * @param token the token to be sent contract address
     * @param _receiver the token to be sent contract address
     * @param _amount the amount to be sent 
     */
    function sendToken(address _receiver, uint256 _amount, address token) public noReentrant onlyAdmin {
      
      IERC20(token).approve(_receiver, _amount);

      IERC20(token).transferFrom(address(this), _receiver,  _amount);
  
    }

}

