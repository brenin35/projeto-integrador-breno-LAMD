import express from 'express'
import swaggerUi from 'swagger-ui-express'
import { router as usersRouter } from './src/controllers/users.controller.js'
import { router as tripsRouter } from './src/controllers/trips.controller.js'
import { router as seatRequestsRouter } from './src/controllers/seat_requests.controller.js'
import { openApiDoc } from './src/openapi.js'

const app = express()
const port = 3000

app.use(express.json())

app.get('/', (_req, res) => {
    res.redirect('/docs')
})

app.use('/docs', swaggerUi.serve, swaggerUi.setup(openApiDoc, {
    customSiteTitle: 'Caronascar API — Docs',
}))

app.use('/users', usersRouter)
app.use('/trips', tripsRouter)
app.use('/seat-requests', seatRequestsRouter)

app.listen(port, () => {
    console.log(`API escutando em http://localhost:${port}`)
    console.log(`Docs disponíveis em http://localhost:${port}/docs`)
})
