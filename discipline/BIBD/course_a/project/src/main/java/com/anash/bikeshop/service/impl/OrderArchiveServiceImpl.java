package com.anash.bikeshop.service.impl;

import com.anash.bikeshop.entity.OrderArchive;
import com.anash.bikeshop.repository.OrderArchiveRepo;
import com.anash.bikeshop.service.OrderArchiveService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class OrderArchiveServiceImpl implements OrderArchiveService {

    @Autowired
    private OrderArchiveRepo orderArchiveRepo;

    @Override
    public void create(OrderArchive orderArchive) {
        OrderArchive createdArchive = orderArchive;
        orderArchiveRepo.saveAndFlush(createdArchive);
    }

    @Override
    public void update(OrderArchive ordersArchive) {
        orderArchiveRepo.saveAndFlush(ordersArchive);
    }

    @Override
    public void delete(OrderArchive ordersArchive) {
        orderArchiveRepo.delete(ordersArchive);
    }

    @Override
    public OrderArchive getById(Integer id) {
        return orderArchiveRepo.findOne(id);
    }

    @Override
    public List<OrderArchive> getAll() {
        return orderArchiveRepo.findAll();
    }

    @Override
    public List<OrderArchive> getOrdersByUserId(Integer id) {

        List<OrderArchive> archive = orderArchiveRepo.findAll();
        ArrayList<OrderArchive> userArchive = new ArrayList<>();

        for (OrderArchive order : archive) {
            if (id == order.getUser().getId()) {
                userArchive.add(order);
            }
        }

        return userArchive;
    }
}
