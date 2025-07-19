const chai = require("chai");
const chaiHttp = require("chai-http");
const server = require("../server.js");
const should = chai.should();

chai.use(chaiHttp);

describe("Items CRUD Tests", () => {
    let createdItemId;
    let nonExistentId = "aaaaaaaaaaaaaaaaaaaaaaaa"; // valid but non-existent ObjectId

    it("should add a new item", (done) => {
        const item = {
            title: "Have a good trip"
        };
        chai.request(server).post("/items/").send(item).end((err, res) => {
            res.should.have.status(201);
            chai.expect(res.body.title).to.equal("Have a good trip");
            createdItemId = res.body._id;
            done();
        });
    });

    it("should get all items", (done) => {
        chai.request(server).get("/items").end((err, res) => {
            res.should.have.status(200);
            res.body.should.be.a("array");
            done();
        });
    });

    it("should get an item with param", (done) => {
        chai.request(server).get(`/items/${createdItemId}`).end((err, res) => {
            res.should.have.status(200);
            res.body.should.be.a("object");
            done();
        });
    });

    it("should can't find any product from list", (done) => {
        chai.request(server).get(`/items/${nonExistentId}`).end((err, res) => {
            res.should.have.status(404);
            done();
        });
    });

    it("should update first item", (done) => {
        const item = {
            title: "Cycling tour",
            order: 5,
            completed: true
        };
        chai.request(server).put(`/items/${createdItemId}`).send(item).end((err, res) => {
            res.should.have.status(204);
            done();
        });
    });

    it("should can't find and updated an item", (done) => {
        const item = {
            title: "Cycling tour",
            order: 5,
            completed: true
        };
        chai.request(server).put(`/items/${nonExistentId}`).send(item).end((err, res) => {
            res.should.have.status(404);
            done();
        });
    });

    it("should delete an item", (done) => {
        // Create a new item to delete
        const item = { title: "To be deleted" };
        chai.request(server).post("/items/").send(item).end((err, res) => {
            const idToDelete = res.body._id;
            chai.request(server).delete(`/items/${idToDelete}`).end((err, res) => {
                res.should.have.status(204);
                done();
            });
        });
    });

});