use openzeppelin::access::ownable::interface::{IOwnableDispatcher, IOwnableDispatcherTrait};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;
// use token_sale::interfaces::ierc20::{IERC20Dispatcher, IERC20DispatcherTrait};
use token_sale::interfaces::itoken_sale::{ITokenSaleDispatcher, ITokenSaleDispatcherTrait};

// Test Accounts
fn OWNER() -> ContractAddress {
    'OWNER'.try_into().unwrap()
}
fn ACCEPTED_TOKEN() -> ContractAddress {
    'ACCEPTED_TOKEN'.try_into().unwrap()
}

#[starknet::interface]
pub trait IERC20PlusMint<TContractState> {
    // IERC20 methods
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256,
    ) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;

    //IERC20Metadata methods
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn decimals(self: @TContractState) -> u8;

    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
}

fn deploy_contract() -> (ITokenSaleDispatcher, IOwnableDispatcher) {
    // declare contract
    let contract_class = declare("TokenSale").expect('failed to declare').contract_class();

    // serialize constructor args
    let mut calldata: Array<felt252> = array![];
    OWNER().serialize(ref calldata);
    ACCEPTED_TOKEN().serialize(ref calldata);

    // deploy contract
    let (contract_address, _) = contract_class.deploy(@calldata).expect('failed to deploy');
    let token_sale = ITokenSaleDispatcher { contract_address };
    let ownable = IOwnableDispatcher { contract_address };
    (token_sale, ownable)
}

#[test]
fn test_contract_deploy() {
    let (_, ownable) = deploy_contract();

    assert(ownable.owner() == OWNER(), 'owner not set');
}

#[test]
fn test_check_available_token() {
    // 1. Declarar y desplegar el contrato TokenSale
    let (token_sale, _) = deploy_contract();

    // 2. Declarar y desplegar un mock ERC20 que permita mint()
    let erc20_class = declare("TestERC20").unwrap().contract_class();
    let (erc20_address, _) = erc20_class.deploy(@ArrayTrait::new()).unwrap();
    let erc20 = IERC20PlusMintDispatcher { contract_address: erc20_address };

    // 3. Mint tokens al contrato TokenSale
    let sale_address = token_sale.contract_address;
    erc20.mint(sale_address, 1000_u256);

    // 4. Llamar check_available_token() desde token_sale
    let available = token_sale.check_available_token(erc20_address);

    // 5. Validar que el resultado sea 1000
    assert(available == 1000_u256, 'Wrong available amount');
}
