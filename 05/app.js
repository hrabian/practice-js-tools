const form = document.querySelector('#wash-form');
const busNumberInput = document.querySelector('#busNumber');
const washDateInput = document.querySelector('#washDate');
const feedback = document.querySelector('#feedback');
const monthTitle = document.querySelector('#month-title');
const tableBody = document.querySelector('#monthly-table-body');

const API_BASE = '/api/washes';

function renderRows(washes) {
  tableBody.innerHTML = '';

  if (washes.length === 0) {
    const row = document.createElement('tr');
    row.innerHTML = '<td colspan="2" class="empty-row">Brak wpisów dla bieżącego miesiąca.</td>';
    tableBody.appendChild(row);
    return;
  }

  washes.forEach((wash) => {
    const row = document.createElement('tr');

    const numberCell = document.createElement('td');
    numberCell.textContent = wash.bus_number;

    const dateCell = document.createElement('td');
    dateCell.textContent = new Intl.DateTimeFormat('pl-PL').format(new Date(wash.wash_date));

    row.append(numberCell, dateCell);
    tableBody.appendChild(row);
  });
}

function setFeedback(message, type) {
  feedback.textContent = message;
  feedback.className = `feedback ${type}`;
}

async function loadCurrentMonthWashes() {
  const monthName = new Intl.DateTimeFormat('pl-PL', { month: 'long', year: 'numeric' }).format(new Date());
  monthTitle.textContent = `Umyte autobusy: ${monthName}`;

  try {
    const response = await fetch(`${API_BASE}/current-month`);

    if (!response.ok) {
      throw new Error('Nie udało się pobrać danych.');
    }

    const washes = await response.json();
    renderRows(washes);
  } catch {
    renderRows([]);
    setFeedback('Wystąpił problem z pobraniem danych z bazy SQLite.', 'error');
  }
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();

  const busNumber = busNumberInput.value.trim();
  const washDate = washDateInput.value;

  if (!busNumber || !washDate) {
    setFeedback('Uzupełnij numer autobusu i datę mycia.', 'error');
    return;
  }

  try {
    const response = await fetch(API_BASE, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        busNumber,
        washDate,
      }),
    });

    if (!response.ok) {
      throw new Error('Nie udało się dodać wpisu.');
    }

    form.reset();
    setFeedback('Dodano umyty autobus.', 'success');
    await loadCurrentMonthWashes();
  } catch {
    setFeedback('Nie udało się zapisać wpisu do bazy SQLite.', 'error');
  }
});

loadCurrentMonthWashes();
