# Buy-and-Renew Smart Contract

## Overview
The **buy-and-renew** contract is designed to simplify the process of purchasing and maintaining names across multiple marketplaces in the BNS ecosystem.  

It introduces an automated workflow that:
1. **Buys a name** across supported marketplaces.
2. **Renews the name** automatically for a user-defined number of cycles (from **1 up to 100**).
3. **Transfers the name** securely to the final buyer.

---

## Motivation
The BNS-V2 contract enforces a restriction:  
> Only the **contract-caller** who is also the **owner** of the name can execute operations on that name.

This limitation makes it difficult for third parties (such as marketplaces, custodial services, or automation layers) to streamline operations for end users.  

The **buy-and-renew** contract provides a workaround by acting as an **intermediary owner**:
- The contract itself purchases the name.
- As the new owner, it is able to execute the renewal logic.
- Finally, ownership is transferred to the intended buyer.

---

## Workflow
1. **Purchase**  
   The contract initiates the buy action for a given name on the marketplace.

2. **Renew**  
   Using a loop implemented with `fold`, the contract performs the number of renewals chosen by the user (**1–100**), ensuring the name is secured for the desired time.

3. **Transfer**  
   After renewal, the name is safely transferred to the buyer specified in the initial purchase transaction.

---

## Advantages
- ✅ **Bypass BNS-V2 limitations**: operations are executed because the contract temporarily becomes the name owner.  
- ✅ **Automation**: no need for manual renewals, thanks to the loop-based renewal system.  
- ✅ **Security**: the buyer ultimately receives full ownership, with no extra steps required.  
- ✅ **Flexibility**: the buyer decides how many renewals to apply, up to 100.  
- ✅ **Scalability**: works across different marketplaces in the ecosystem.  

---

## Technical Notes
- Implemented in [Clarity](https://docs.stacks.co/write-smart-contracts/clarity-language).  
- Uses `fold` for efficient looped renewals.  
- Designed to remain lightweight while handling ownership transitions safely.  

---

## Example Use Case
A user wants to buy a name listed on a marketplace and ensure it remains renewed for the next 25 cycles.  
Instead of:
- Manually buying the name.  
- Manually renewing the name 25 times.  

The **buy-and-renew** contract performs the entire process in one atomic workflow, with the user simply specifying `renewals = 25`.

---

## Future Improvements
- Add support for **configurable marketplace fees**.  
- Integration with more marketplaces.  
- Event logging for better on-chain traceability.  

---

## License
MIT
