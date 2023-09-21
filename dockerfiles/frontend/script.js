// script.js
const loginForm = document.getElementById('login-form');
const balanceContainer = document.getElementById('balance-container');
const displayAccount = document.getElementById('display-account');
const displayBalance = document.getElementById('display-balance');

loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const accountNumber = document.getElementById('account-number').value;
    const password = document.getElementById('password').value;

    const response = await fetch('/login', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ accountNumber, password })
    });

    if (response.status === 200) {
        const account = await response.json();
        displayAccount.textContent = account.accountNumber;
        displayBalance.textContent = account.balance;
        balanceContainer.style.display = 'block';
    } else {
        alert('Invalid credentials');
    }
});
