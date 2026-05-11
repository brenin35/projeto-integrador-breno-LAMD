import express from 'express'
import { router as usersRouter } from './src/controllers/users.controller.js'
import { router as tripsRouter } from './src/controllers/trips.controller.js'
import { router as seatRequestsRouter } from './src/controllers/seat_requests.controller.js'

const app = express()
const port = 3000

app.use(express.json())

app.get('/', (req, res) => {
    res.send('Hello World!')
})

app.use('/users', usersRouter)
app.use('/trips', tripsRouter)
app.use('/seat-requests', seatRequestsRouter)

app.listen(port, () => {
    console.log(`Example app listening on port ${port}`)
})