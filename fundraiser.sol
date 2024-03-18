//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address owner) external returns (uint256);
}

contract fundraiser {
    address public owner;
    uint256 public hardcap = 500 * 1e18; // 500
    uint256 public minContribution = 0.01 * 1e18;// 0.01
    uint256 public maxContribution = 10 * 1e18; // 10
    uint256 public startTimestamp; // you may also hard code the timestamp.
    uint256 public endTimestamp;
    mapping(address=>uint256) public contributors;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    constructor() {
        owner = msg.sender;
    }
    receive() external payable {
        address sender = msg.sender;
        require(msg.sender == tx.origin, "EOA Only");
        require(block.timestamp > startTimestamp, "not started");
        require(block.timestamp < endTimestamp, "ended");
        require(address(this).balance < hardcap, "hardcap filled");
        require(msg.value >= minContribution, "minContribution not reached");
        require(msg.value <= maxContribution, "maxContribution not reached");
        contributors[sender] = contributors[sender] + msg.value; 
        // refund the rest
        if(contributors[sender] > maxContribution) {
            uint256 refund = contributors[sender] - maxContribution;
            contributors[sender] = maxContribution;
            (bool success, ) = address(sender).call{value:refund}("");
            require(success);
        }
    }
    function setCap(uint256 _min, uint256 _max, uint256 _hardcap) external onlyOwner {
        minContribution = _min;
        maxContribution = _max;
        hardcap = _hardcap;
    }
    function setTimestamp(uint256 _start, uint256 _end) external onlyOwner {
        startTimestamp = _start;
        endTimestamp = _end;
    }
    function withdrawNative() external onlyOwner {
        (bool success, ) = address(owner).call{ value: address(this).balance }("");
        require(success);
    }
    function withdrawERC20(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        (bool success) = token.transfer(owner, token.balanceOf(address(this)));
        require(success);
    }
}
