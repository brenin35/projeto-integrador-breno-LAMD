import express from 'express'
import swaggerUi from 'swagger-ui-express'
import { router as authRouter } from './src/controllers/auth.controller.js'
import { router as usersRouter } from './src/controllers/users.controller.js'
import { router as tripsRouter } from './src/controllers/trips.controller.js'
import { router as seatRequestsRouter } from './src/controllers/seat_requests.controller.js'
import { openApiDoc } from './src/openapi.js'
import { getChannel } from './src/messaging/connection.js'

const app = express()
const port = 3000

app.use(express.json())

app.get('/', (_req, res) => {
    res.redirect('/docs')
})

app.use('/docs', swaggerUi.serve, swaggerUi.setup(openApiDoc, {
    customSiteTitle: 'Caronascar API — Docs',
}))

app.use('/auth', authRouter)
app.use('/users', usersRouter)
app.use('/trips', tripsRouter)
app.use('/seat-requests', seatRequestsRouter)

app.listen(port, () => {
    console.log(`API escutando em http://localhost:${port}`)
    console.log(`Docs disponíveis em http://localhost:${port}/docs`)

    getChannel()
        .then(() => console.log('MOM (RabbitMQ) conectado e exchange declarado'))
        .catch((err) => console.warn(`MOM indisponível no boot: ${err.message} (será reconectado sob demanda)`))
})
