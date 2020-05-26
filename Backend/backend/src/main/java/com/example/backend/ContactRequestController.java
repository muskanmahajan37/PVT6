package com.example.backend;

import java.util.HashSet;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import antlr.collections.List;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;

@Controller // This means that this class is a Controller
@RequestMapping(path = "/contacts")
public class ContactRequestController {
    @Autowired // This means to get the bean called userRepository
    // Which is auto-generated by Spring, we will use it to handle the data
    private UserRepository userRepository;

    @GetMapping(path = "/sentRequests")
    public @ResponseBody Set<ContactRequest> getContactRequests(@RequestParam String uid) {
        Set<ContactRequest> sent = new HashSet<ContactRequest>();
        Set<ContactRequest> list = userRepository.findByUid(uid).getContactRequest();
        User user = userRepository.findByUid(uid);
        for (ContactRequest e : list) {

            if(e.getSender() != null && e.getSender().getUid() == user.getUid()){
                sent.add(e);
            }

        }
        return sent;
    }
    @GetMapping(path = "/waitingRequests")
    public @ResponseBody Set<ContactRequest> getWaitingContactRequests(@RequestParam String uid) {
        Set<ContactRequest> sent = new HashSet<ContactRequest>();
        Set<ContactRequest> list = userRepository.findByUid(uid).getContactRequest();
        User user = userRepository.findByUid(uid);
        for (ContactRequest e : list) {

            if(e.getSender() != null && e.getSender().getUid() != user.getUid()){
                sent.add(e);
            }

        }
        return sent;
      
    }
    @GetMapping(path = "/clearRequests")
    public @ResponseBody String clearRequests(@RequestParam String uid){
        User u = userRepository.findByUid(uid);
        u.getContactRequest().clear();
        userRepository.save(u);
        return "true";
    }


    @PostMapping(path = "/answer")
    public @ResponseBody String answerRequest(@RequestParam String e, String phone, String uid) {
        User u = userRepository.findByUid(uid);
        User u2 = userRepository.findByPhone(phone);

        Set<ContactRequest> contactRequests = u.getContactRequest();
        contactRequests.forEach((element) -> {
            if (element.getSender() == u2) {
                switch (e) {
                    case "accept":
                        element.setStatus(Status.ACCEPTED);
                        u2.findUserFromContactRequests(element).setStatus(Status.ACCEPTED);
                        // ADD TO FRIENDS
                        if(u.getContactList() == null){
                            u.setContactList(new ContactList());
                            userRepository.saveAndFlush(u);
                        }
                        if(u2.getContactList() == null){
                            u2.setContactList(new ContactList());
                            userRepository.saveAndFlush(u2);
                        }
                      
                   
                        u.getContactList().addUser(u2);
                        u2.getContactList().addUser(u);
                        userRepository.save(u);
                        userRepository.save(u2);
                     
                        break;
                    case "rejcet":
                        element.setStatus(Status.REJECTRED);
                        u2.findUserFromContactRequests(element).setStatus(Status.ACCEPTED);
                        userRepository.save(u);
                        userRepository.save(u2);
                        break;
                }
               
                
            }

        });
        return "true";

    }

    @GetMapping(path = "/all")
    public @ResponseBody ContactList getContacts(@RequestParam String uid) {
        return userRepository.findByUid(uid).getContactList();
    }

    @PostMapping(path = "/remove")
    public @ResponseBody String removeContact(@RequestParam String uid, String phone) {
        User u1 = userRepository.findByUid(uid);
        User u2 = userRepository.findByPhone(phone);
        
        u1.getContactList().getUser().remove(u2);
        u2.getContactList().getUser().remove(u1);
        userRepository.save(u1);
        userRepository.save(u2);

         return "true";
    }

    @PostMapping(value = "/new")
    public @ResponseBody String sendRequest(@RequestParam String sendUid, String phone) {
        User sender = userRepository.findByUid(sendUid);
        User receiver = userRepository.findByPhone(phone);
        if (receiver != null) {
            ContactRequest request = new ContactRequest(sender, receiver, Status.WAITING);
            sender.setContactRequest(request);
            receiver.setContactRequest(request);
            userRepository.save(sender);
            userRepository.save(receiver);
            return "Sent friend request";
        } else
            return "No user found";
    }
    @PostMapping(value = "/cancleRequests")
    public @ResponseBody String cancleRequests(@RequestParam String uid, String phone){
        User sender = userRepository.findByUid(uid);
        User receiver = userRepository.findByPhone(phone);

        Set<ContactRequest> contactRequests = sender.getContactRequest();
        contactRequests.forEach((e) -> {
            if(e.getReceiver() == receiver){
                contactRequests.remove(e);
                userRepository.saveAndFlush(sender);
            }
        });
        Set<ContactRequest> contactRequests2 = receiver.getContactRequest();
        contactRequests.forEach((e) -> {
            if(e.getSender() == sender){
                contactRequests.remove(e);
                userRepository.saveAndFlush(sender);
            }
        });

        return "true";
        }

}