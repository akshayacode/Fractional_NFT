// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FERC1155.sol";
import "./Vault.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract VaultFactory is Ownable, ERC1155Holder {
    string public version = "0.1";
    /// @notice the number of ERC721 vaults
    uint256 public vaultCount;

    /// @notice the mapping of vault number to vault contract
    mapping(uint256 => address) public vaults;

    /// @notice a settings contract controlled by governance
    address public feeReceiver;
    /// @notice the fractional ERC1155 NFT contract
    address public immutable fnft;
        /// @notice ommni token address
    address public immutable ommni;

    event Mint(
        address indexed token,
        uint256 id,
        uint256 fractionId,
        address vault,
        uint256 vaultId
    );

    constructor(address _fnft, address _ommni) {
        fnft = _fnft;
        ommni = _ommni;
    }

    /// @notice the function to mint a new vault
    /// @param _token the ERC721 token address fo the NFT
    /// @param _id the uint256 ID of the token
    /// @param _amount the amount of tokens to
    /// @return the ID of the vault
    function mintVault(
        address _token,
        uint256 _id,
        uint256 _amount
    ) external returns (uint256) {
        uint256 count = FERC1155(fnft).count() + 1;
        address vault = address(
            new Vault(ommni, fnft, count, _token, _id, msg.sender,_amount)
        );
        uint256 fractionId = FERC1155(fnft).mint(vault, _amount);
        require(count == fractionId, "mismatch");

        emit Mint(_token, _id, fractionId, vault, vaultCount);
        IERC721(_token).safeTransferFrom(msg.sender, vault, _id);
        FERC1155(fnft).safeTransferFrom(
            address(this),
            vault,
            fractionId,
            _amount,
            bytes("0")
        );

        vaults[vaultCount] = vault;
        vaultCount++;

        return vaultCount - 1;
    }

    function setFees(address _fees) external onlyOwner {
        feeReceiver = _fees;
    }
}
