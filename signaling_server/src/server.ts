import express, { NextFunction } from 'express'
import { Router, Request, Response } from 'express';

const port = 8080;
const app = express();
const route = Router();
let idCounter = 0

function logRequest(req: Request, res: Response, next: NextFunction) {
    const url = req.url;
    const method = req.method;
    console.log(`${method} ${url} - Pending\nBody:${JSON.stringify(req.body, undefined, 2)}`);
    res.on('finish', () => {
        console.log(`${method} ${url} - ${res.statusCode}`);
    });
    next();
}

type Room = {
    ip: string,
    nextPlayerId: number,
    authorityId: number,
}
const rooms = new Map<number, Room>();

app.use(express.json());
app.use(logRequest)

const validateRoomRequest = (req: Request, res: Response, next: NextFunction) => {
    const body = req.body;

    if (!req.ip) return res.status(403).json('IP must be known');
    if (!body.nextPlayerId) return res.status(400).json(`Missing body property 'nextPlayerId'`)
    if (typeof body.nextPlayerId != 'number') return res.status(400).json(`nextPlayerId must be a number`);
    if (body.nextPlayerId < 0) return res.status(400).json(`nextPlayerId must be positive`);
    if (!body.authorityId) return res.status(400).json(`Missing body property 'authorityId'`)
    if (typeof body.authorityId != 'number') return res.status(400).json(`authorityId must be a number`);
    if (body.authorityId < 0) return res.status(400).json(`authorityId must be positive`);

    next();
}

const merge = (req: Request, res: Response, next: NextFunction) => {
    req.body = { ...rooms.get(parseInt(req.params.id)), ...req.body }
    next()
}

const validateRoomId = (req: Request, res: Response, next: NextFunction) => {
    if (!rooms.has(parseInt(req.params.id))) return res.status(404).json();
    next();
}

route.get('/rooms', (req: Request, res: Response) => {
    res.status(200).json(Object.fromEntries(rooms));
})

route.post('/rooms', validateRoomRequest, (req: Request, res: Response) => {
    // Parse body
    const body = req.body;

    // Add to room list
    rooms.set(idCounter++, {
        ip: req.ip!.split(':').pop()!,
        nextPlayerId: body.nextPlayerId,
        authorityId: body.authorityId,
    });

    // Send room id back
    res.status(200).json(idCounter - 1);
})

route.patch('/rooms/:id', validateRoomId, merge, validateRoomRequest, (req: Request, res: Response) => {
    // Parse body
    const body = req.body;
    rooms.set(parseInt(req.params.id), {
        ip: req.ip!.split(':').pop()!,
        nextPlayerId: body.nextPlayerId,
        authorityId: body.authorityId,
    });
    res.status(200).json();
});

route.delete('/rooms/:id', validateRoomId, (req: Request, res: Response) => {
    rooms.delete(parseInt(req.params.id));
    res.status(200).json();
})

app.use(route)


app.listen(port, () => console.log(`Room server running on port ${port}`));