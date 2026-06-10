// Burger menu toggle
const burgerMenu = document.getElementById('burgerMenu')
const navMenu = document.getElementById('navMenu')

burgerMenu.addEventListener('click', () => {
    burgerMenu.classList.toggle('active')
    navMenu.classList.toggle('active')
})

// Close menu when clicking on a link
navMenu.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
        burgerMenu.classList.remove('active')
        navMenu.classList.remove('active')
    })
})

// Supabase configuration
const SUPABASE_URL = 'https://tdclhoimzksmqmnsaccw.supabase.co'
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRkY2xob2ltemtzbXFtbnNhY2N3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2NzAxMjUsImV4cCI6MjA3MjI0NjEyNX0.lkxHRLuT4liiDJWt4AnSk24rFY5E3sceyApZ7kVTGL4'

// Handle form submission
document.getElementById('rsvpForm').addEventListener('submit', async (e) => {
    e.preventDefault()

    const submitButton = e.target.querySelector('button[type="submit"]')
    const originalText = submitButton.textContent
    submitButton.textContent = 'SUBMITTING...'
    submitButton.disabled = true

    try {
        const formData = new FormData(e.target)
        const attending = formData.get('attending')

        // Map form values to RSVP status
        let rsvpStatus = 'pending'
        if (attending === 'yes') {
            rsvpStatus = 'attending'
        } else if (attending === 'no') {
            rsvpStatus = 'not_attending'
        }

        const guestData = {
            guest_name: formData.get('name'),
            email: formData.get('email') || null,
            phone: formData.get('phone') || null,
            rsvp_status: rsvpStatus,
            number_of_guests: parseInt(formData.get('guests')) || 1,
            dietary_restrictions: formData.get('dietary') || null,
            plus_one_name: formData.get('plusOne') || null,
            message: formData.get('message') || null,
            rsvp_date: new Date().toISOString()
        }

        // Submit to Supabase
        const response = await fetch(`${SUPABASE_URL}/rest/v1/wedding_guests`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'apikey': SUPABASE_ANON_KEY,
                'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
                'Prefer': 'return=representation'
            },
            body: JSON.stringify(guestData)
        })

        if (!response.ok) {
            throw new Error('Failed to submit RSVP')
        }

        // Redirect based on RSVP status
        if (rsvpStatus === 'not_attending') {
            window.location.href = 'sorry.html'
        } else {
            window.location.href = 'thankyou.html'
        }
    } catch (error) {
        console.error('Error submitting RSVP:', error)
        alert('Sorry, there was an error submitting your RSVP. Please try again or contact us directly.')
        submitButton.textContent = originalText
        submitButton.disabled = false
    }
})

// Update plus one field visibility based on number of guests
document.getElementById('guests').addEventListener('input', (e) => {
    const plusOneField = document.getElementById('plusOne').closest('.form-group')
    if (parseInt(e.target.value) > 1) {
        plusOneField.style.display = 'block'
    } else {
        plusOneField.style.display = 'none'
    }
})

// Hide dietary requirements if not attending
document.querySelectorAll('input[name="attending"]').forEach(radio => {
    radio.addEventListener('change', (e) => {
        const dietaryField = document.getElementById('dietary').closest('.form-group')
        const guestsField = document.getElementById('guests').closest('.form-group')
        const plusOneField = document.getElementById('plusOne').closest('.form-group')

        if (e.target.value === 'no') {
            dietaryField.style.display = 'none'
            guestsField.style.display = 'none'
            plusOneField.style.display = 'none'
        } else {
            dietaryField.style.display = 'block'
            guestsField.style.display = 'block'
            if (parseInt(document.getElementById('guests').value) > 1) {
                plusOneField.style.display = 'block'
            }
        }
    })
})